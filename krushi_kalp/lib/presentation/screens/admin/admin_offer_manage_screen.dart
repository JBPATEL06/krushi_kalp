import 'package:flutter/material.dart';
import '../../../../domain/models/offer.dart';
import '../../../../domain/models/mock_test.dart';
import '../../../../data/services/offer_service.dart';
import '../../../../data/services/test_service.dart';
import '../../../../data/services/admin_service.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:intl/intl.dart';

class AdminOfferManageScreen extends StatefulWidget {
  final Offer? offer; // If provided, Edit mode. Else, Create mode.
  const AdminOfferManageScreen({super.key, this.offer});

  @override
  State<AdminOfferManageScreen> createState() => _AdminOfferManageScreenState();
}

class _AdminOfferManageScreenState extends State<AdminOfferManageScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _valueController;
  late TextEditingController _minOrderController;
  late TextEditingController _maxDiscountController;

  String _discountType = 'FLAT';
  String _targetType = 'ALL';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _isReal = true;
  bool _isSale = false;

  List<dynamic> _selectedTargetIds = [];
  List<MockTest> _availableTests = [];
  List<Map<String, dynamic>> _availableUsers = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _codeController = TextEditingController(text: o?.code);
    _titleController = TextEditingController(text: o?.title);
    _descriptionController = TextEditingController(text: o?.description);
    _valueController = TextEditingController(text: o?.discountValue.toString());
    _minOrderController =
        TextEditingController(text: o?.minOrderValue?.toString());
    _maxDiscountController =
        TextEditingController(text: o?.maxDiscount?.toString());

    if (o != null) {
      _discountType = o.discountType;
      _targetType = o.targetType;
      _startDate = o.startDate ?? DateTime.now();
      _endDate = o.endDate ?? DateTime.now().add(const Duration(days: 30));
      _isActive = o.isActive;
      _isReal = o.isReal;
      _isSale = o.isSale;
      _selectedTargetIds = List.from(o.targetIds);
    }

    _loadSelectionData();
  }

  Future<void> _loadSelectionData() async {
    setState(() => _isLoadingData = true);
    try {
      _availableTests = await TestService.instance.fetchMockTests();
      _availableUsers = await AdminService.getAllUsers();
    } catch (e) {
      debugPrint("Error loading selection data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    final discountVal = double.tryParse(_valueController.text) ?? 0;
    if (_discountType == 'PERCENTAGE' && discountVal > 99.99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Percentage discount cannot exceed 99.99%')),
      );
      return;
    }

    if (_targetType != 'ALL' && _selectedTargetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one Test or User')),
      );
      return;
    }

    final newOffer = Offer(
      id: widget.offer?.id ?? 0,
      code: (_isSale || _codeController.text.isEmpty)
          ? null
          : _codeController.text.toUpperCase(),
      title: _titleController.text,
      description: _descriptionController.text,
      discountType: _discountType,
      discountValue: double.parse(_valueController.text),
      startDate: _startDate.toUtc(),
      endDate: _endDate.toUtc(),
      isActive: _isActive,
      targetType: _targetType,
      targetIds: _selectedTargetIds,
      minOrderValue: double.tryParse(_minOrderController.text),
      maxDiscount: double.tryParse(_maxDiscountController.text),
      isReal: _isReal,
      isSale: _isSale,
    );

    try {
      if (widget.offer == null) {
        await OfferService.instance.createOffer(newOffer);
      } else {
        await OfferService.instance.updateOffer(newOffer);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showTestSelector() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selected = await showDialog<List<int>>(
      context: context,
      builder: (ctx) {
        final tempSelected =
            List<int>.from(_selectedTargetIds.whereType<int>());
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Tests'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableTests.length,
                  itemBuilder: (ctx, i) {
                    final test = _availableTests[i];
                    final isSelected = tempSelected.contains(test.id);
                    return CheckboxListTile(
                      title: Text(test.title),
                      value: isSelected,
                      activeColor: colorScheme.primary,
                      onChanged: (v) {
                        setState(() {
                          if (v!)
                            tempSelected.add(test.id);
                          else
                            tempSelected.remove(test.id);
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, tempSelected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected != null) setState(() => _selectedTargetIds = selected);
  }

  void _showUserSelector() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedUser = await showDialog<List<String>>(
      context: context,
      builder: (ctx) {
        final tempSelected =
            List<String>.from(_selectedTargetIds.whereType<String>());
        String query = "";
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredUsers = _availableUsers.where((u) {
              final email = (u['email'] ?? '').toString().toLowerCase();
              final name = (u['username'] ?? '').toString().toLowerCase();
              return email.contains(query.toLowerCase()) ||
                  name.contains(query.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Select Users'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredUsers.length,
                        itemBuilder: (ctx, i) {
                          final user = filteredUsers[i];
                          final uid = user['id'] as String;
                          final isSelected = tempSelected.contains(uid);
                          return CheckboxListTile(
                            title: Text(user['username'] ?? 'User'),
                            subtitle: Text(user['email'] ?? ''),
                            value: isSelected,
                            activeColor: colorScheme.primary,
                            onChanged: (v) {
                              setState(() {
                                if (v!)
                                  tempSelected.add(uid);
                                else
                                  tempSelected.remove(uid);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, tempSelected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selectedUser != null) setState(() => _selectedTargetIds = selectedUser);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(widget.offer == null ? 'Create Offer' : 'Edit Offer'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl + MediaQuery.of(context).padding.bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, "GENERAL INFORMATION"),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _codeController,
                          enabled: !_isSale,
                          decoration: InputDecoration(
                            labelText: _isSale
                                ? "Coupon Code (N/A for Sales)"
                                : "Unique Coupon Code",
                            hintText: "e.g. KRUSHI50",
                            prefixIcon:
                                const Icon(Icons.confirmation_number_rounded),
                          ),
                          validator: (v) =>
                              (!_isSale && v!.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: "Display Title",
                            hintText: "e.g. Festival Special Discount",
                            prefixIcon: Icon(Icons.label_rounded),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: "Short Description",
                            hintText: "Visible to users on checkout",
                            prefixIcon: Icon(Icons.description_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildSectionHeader(context, "DISCOUNT CONFIGURATION"),
                        const SizedBox(height: AppSpacing.lg),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 350;

                            final typeField = DropdownButtonFormField<String>(
                              value: _discountType,
                              isExpanded:
                                  true, // Prevents overflow if items are long
                              decoration: const InputDecoration(
                                labelText: "Type",
                                prefixIcon: Icon(Icons.percent_rounded),
                              ),
                              items: ['FLAT', 'PERCENTAGE']
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _discountType = v!),
                            );

                            final valueField = TextFormField(
                              controller: _valueController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Value",
                                prefixIcon: Icon(Icons.attach_money_rounded),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            );

                            if (isNarrow) {
                              return Column(
                                children: [
                                  typeField,
                                  const SizedBox(height: AppSpacing.lg),
                                  valueField,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: typeField),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(child: valueField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        DropdownButtonFormField<String>(
                          value: _targetType,
                          decoration: const InputDecoration(
                            labelText: "Apply To",
                            prefixIcon: Icon(Icons.gps_fixed_rounded),
                          ),
                          items: (_isSale
                                  ? ['ALL', 'TEST']
                                  : ['ALL', 'USER', 'TEST'])
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _targetType = v!;
                              _selectedTargetIds.clear();
                            });
                          },
                        ),
                        if (_targetType != 'ALL') ...[
                          const SizedBox(height: AppSpacing.lg),
                          _buildPickerTile(
                            context,
                            label: _targetType == 'TEST'
                                ? "Select Mock Tests"
                                : "Select Targeted Users",
                            subtitle:
                                "${_selectedTargetIds.length} items selected",
                            icon: _targetType == 'TEST'
                                ? Icons.list_alt_rounded
                                : Icons.people_rounded,
                            onTap: _targetType == 'TEST'
                                ? _showTestSelector
                                : _showUserSelector,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildSectionHeader(context, "AVAILABILITY & CONTROLS"),
                        const SizedBox(height: AppSpacing.lg),
                        _buildPickerTile(
                          context,
                          label: "Validity Window",
                          subtitle:
                              "${DateFormat.yMMMd().format(_startDate)} - ${DateFormat.yMMMd().format(_endDate)}",
                          icon: Icons.calendar_today_rounded,
                          onTap: () async {
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2030),
                              initialDateRange: DateTimeRange(
                                  start: _startDate, end: _endDate),
                            );
                            if (range != null) {
                              setState(() {
                                _startDate = range.start;
                                _endDate = range.end;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SwitchListTile(
                          title: const Text("Is Active"),
                          subtitle: const Text("Enable this offer for users"),
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                        SwitchListTile(
                          title: const Text("Is Store Sale"),
                          subtitle:
                              const Text("Auto-apply without coupon code"),
                          value: _isSale,
                          onChanged: (v) {
                            setState(() {
                              _isSale = v;
                              if (_isSale) {
                                if (_targetType == 'USER') {
                                  _targetType = 'ALL';
                                  _selectedTargetIds.clear();
                                }
                                _codeController.clear();
                                _isReal = true;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saveOffer,
                            icon: const Icon(Icons.save_rounded),
                            label:
                                Text(_isSale ? 'CREATE SALE' : 'SAVE COUPON'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildPickerTile(BuildContext context,
      {required String label,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(label, style: theme.textTheme.labelLarge),
      subtitle: Text(subtitle,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant)),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }
}
