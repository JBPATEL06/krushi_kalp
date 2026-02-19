import 'package:flutter/material.dart';
import '../../../../domain/models/offer.dart';
import '../../../../domain/models/mock_test.dart';
import '../../../../data/services/offer_service.dart';
import '../../../../data/services/test_service.dart';
import '../../../../data/services/admin_service.dart';
import '../../utils/ui_helpers.dart'; // NEW

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
  // targetIdsController removed in favor of List state

  String _discountType = 'FLAT';
  String _targetType = 'ALL';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isActive = true;
  bool _isReal = true;
  bool _isSale = false; // NEW

  // Selection Data
  List<dynamic> _selectedTargetIds =
      []; // Stores IDs (int for Tests, String for Users)
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
      _isSale = o.isSale; // NEW
      _selectedTargetIds = List.from(o.targetIds);
    }

    _loadSelectionData();
  }

  Future<void> _loadSelectionData() async {
    setState(() => _isLoadingData = true);
    try {
      _availableTests = await TestService.fetchMockTests();
      _availableUsers = await AdminService.getAllUsers();
    } catch (e) {
      debugPrint("Error loading selection data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation for Percentage
    final discountVal = double.tryParse(_valueController.text) ?? 0;
    if (_discountType == 'PERCENTAGE' && discountVal > 99.99) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Percentage discount cannot exceed 99.99%')),
      );
      return;
    }

    // Validation for Target Type
    if (_targetType != 'ALL' && _selectedTargetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one Test or User')),
      );
      return;
    }

    final newOffer = Offer(
      id: widget.offer?.id ?? 0, // Ignored on Insert
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
      minOrderValue: double.tryParse(_minOrderController.text), // Restored
      maxDiscount: double.tryParse(_maxDiscountController.text),
      isReal: _isReal,
      isSale: _isSale, // NEW
    );

    try {
      if (widget.offer == null) {
        await OfferService.createOffer(newOffer);
      } else {
        await OfferService.updateOffer(newOffer);
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
    final selected = await showDialog<List<int>>(
      context: context,
      builder: (ctx) {
        final tempSelected =
            List<int>.from(_selectedTargetIds.whereType<int>());
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select Tests',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300, // Limit height
                      child: ListView.builder(
                        itemCount: _availableTests.length,
                        itemBuilder: (ctx, i) {
                          final test = _availableTests[i];
                          final isSelected = tempSelected.contains(test.id);
                          return CheckboxListTile(
                            title: Text(test.title),
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                if (v!) {
                                  tempSelected.add(test.id);
                                } else {
                                  tempSelected.remove(test.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel')),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, tempSelected),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              foregroundColor: Theme.of(context).primaryColor,
                              elevation: 0),
                          child: const Text('Confirm'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (selected != null) {
      setState(() => _selectedTargetIds = selected);
    }
  }

  void _showUserSelector() async {
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

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Select Users',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (ctx, i) {
                          final user = filteredUsers[i];
                          final uid = user['id'] as String;
                          final isSelected = tempSelected.contains(uid);
                          return CheckboxListTile(
                            title: Text(user['username'] ?? 'User'),
                            subtitle: Text(user['email'] ?? ''),
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                if (v!) {
                                  tempSelected.add(uid);
                                } else {
                                  tempSelected.remove(uid);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel')),
                        const SizedBox(width: 12),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, tempSelected),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[50],
                                foregroundColor: Colors.blue[700],
                                elevation: 0),
                            child: const Text('Confirm')),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selectedUser != null) {
      setState(() => _selectedTargetIds = selectedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.offer == null ? 'Create Offer' : 'Edit Offer',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return buildFormCard(
                    context,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _codeController,
                            enabled: !_isSale, // Disable if Sale
                            decoration: getPremiumInputDecoration(
                              context,
                              labelText: _isSale
                                  ? 'Coupon Code (Not Required)'
                                  : 'Coupon Code (Unique)',
                              hintText: 'SUMMER50',
                              prefixIcon: const Icon(
                                  Icons.confirmation_number_outlined),
                            ),
                            validator: (v) =>
                                (!_isSale && v!.isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: getPremiumInputDecoration(
                              context,
                              labelText: 'Title',
                              hintText: 'Summer Sale',
                              prefixIcon: const Icon(Icons.label_outline),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: getPremiumInputDecoration(
                              context,
                              labelText: 'Description',
                              prefixIcon:
                                  const Icon(Icons.description_outlined),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 10),
                          const SizedBox(height: 10),
                          if (isWide)
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _discountType,
                                    decoration: getPremiumInputDecoration(
                                        context,
                                        labelText: 'Type'),
                                    items: ['FLAT', 'PERCENTAGE']
                                        .map((e) => DropdownMenuItem(
                                            value: e, child: Text(e)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _discountType = v!),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _valueController,
                                    decoration: getPremiumInputDecoration(
                                      context,
                                      labelText: 'Value',
                                      prefixIcon:
                                          const Icon(Icons.attach_money),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            DropdownButtonFormField<String>(
                              initialValue: _discountType,
                              decoration: getPremiumInputDecoration(context,
                                  labelText: 'Type'),
                              items: ['FLAT', 'PERCENTAGE']
                                  .map((e) => DropdownMenuItem(
                                      value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _discountType = v!),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _valueController,
                              decoration: getPremiumInputDecoration(
                                context,
                                labelText: 'Value',
                                prefixIcon: const Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Target Selection
                          DropdownButtonFormField<String>(
                            initialValue: _targetType,
                            decoration: getPremiumInputDecoration(context,
                                labelText: 'Target Type'),
                            items: (_isSale
                                    ? [
                                        'ALL',
                                        'TEST'
                                      ] // Sale only supports these
                                    : ['ALL', 'USER', 'TEST'])
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _targetType = v!;
                                _selectedTargetIds
                                    .clear(); // Reset selection on type change
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          if (_targetType == 'TEST') ...[
                            OutlinedButton.icon(
                                onPressed: _showTestSelector,
                                icon: const Icon(Icons.list),
                                label: const Text('Select Tests to Include')),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedTargetIds.map((id) {
                                final test = _availableTests.firstWhere(
                                    (t) => t.id == id,
                                    orElse: () => MockTest(
                                        id: 0,
                                        title: 'Unknown',
                                        description: '',
                                        category: '',
                                        filePath: '',
                                        price: 0,
                                        totalQuestions: 0,
                                        totalMarks: 0,
                                        negativeMarking: false,
                                        negativeMarksPerQ: 0,
                                        language: 'en',
                                        createdAt: DateTime.now()));
                                return Chip(
                                  label: Text(
                                    test.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onDeleted: () => setState(
                                      () => _selectedTargetIds.remove(id)),
                                );
                              }).toList(),
                            )
                          ] else if (_targetType == 'USER') ...[
                            OutlinedButton.icon(
                                onPressed: _showUserSelector,
                                icon: const Icon(Icons.person_search),
                                label: const Text('Select Users to Include')),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedTargetIds.map((id) {
                                final user = _availableUsers.firstWhere(
                                    (u) => u['id'] == id,
                                    orElse: () =>
                                        {'username': 'Unknown', 'email': '?'});
                                return Chip(
                                  label: Text(
                                      "${user['username']} (${user['email']})"),
                                  onDeleted: () => setState(
                                      () => _selectedTargetIds.remove(id)),
                                );
                              }).toList(),
                            )
                          ],

                          const SizedBox(height: 24),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Start Date'),
                            subtitle: Text(
                                _startDate.toLocal().toString().split(' ')[0]),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030));
                              if (d != null) setState(() => _startDate = d);
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('End Date'),
                            subtitle: Text(
                                _endDate.toLocal().toString().split(' ')[0]),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate,
                                  firstDate: DateTime(2025),
                                  lastDate: DateTime(2030));
                              if (d != null) setState(() => _endDate = d);
                            },
                          ),
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Is Active'),
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v)),
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Real Offer? (Yes/No)'),
                              subtitle: const Text(
                                  'Mark this as a real offer vs test/fake.'),
                              value: _isReal,
                              // Requirement: If "Is Sale" is FALSE (Code-based), "Is Real" MUST be TRUE and locked.
                              // User cannot turn off "Real" for coupon codes.
                              onChanged: !_isSale
                                  ? null
                                  : (v) => setState(() => _isReal = v)),
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Is Store Sale? (Auto-Apply)'),
                              subtitle: const Text(
                                  'If checked, users see this as a sale price without needing a code.'),
                              value: _isSale,
                              onChanged: (v) {
                                setState(() {
                                  _isSale = v;
                                  if (_isSale) {
                                    // Sale usually implies ALL or TEST, not specific USER
                                    if (_targetType == 'USER') {
                                      _targetType = 'ALL';
                                      _selectedTargetIds.clear();
                                    }
                                    _codeController
                                        .clear(); // Clear code for sales
                                  } else {
                                    // If switched TO Coupon Code (Not Sale), enforce Real = True
                                    _isReal = true;
                                  }
                                });
                              }),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _saveOffer,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50)),
                            child: const Text('SAVE OFFER'),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
