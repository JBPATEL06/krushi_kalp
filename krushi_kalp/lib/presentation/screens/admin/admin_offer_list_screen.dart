import 'package:flutter/material.dart';
import '../../../../domain/models/offer.dart';
import '../../../../data/services/offer_service.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_offer_manage_screen.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class AdminOfferListScreen extends StatefulWidget {
  final bool showOnlyActive;
  const AdminOfferListScreen({super.key, this.showOnlyActive = false});

  @override
  State<AdminOfferListScreen> createState() => _AdminOfferListScreenState();
}

class _AdminOfferListScreenState extends State<AdminOfferListScreen> {
  Stream<List<Offer>>? _offersStream;
  int _streamId = 0;

  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  bool _showActiveOnly = false;
  bool _sortByNewest = false;
  String _filterType = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int? _updatingOfferId;

  @override
  void initState() {
    super.initState();
    _showActiveOnly = widget.showOnlyActive;
    _refreshOffers();
  }

  void _refreshOffers() {
    setState(() {
      _streamId++;
      _offersStream = OfferService.instance.streamOffers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(int id) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Offer?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await OfferService.instance.deleteOffer(id);
        if (mounted) {
          if (result == 'ARCHIVED') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Offer is in use. It has been DEACTIVATED instead.'),
                backgroundColor: Color(0xFFF59E0B),
              ),
            );
            _refreshOffers();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Offer deleted successfully.')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: theme.colorScheme.error),
          );
        }
      }
    }
  }

  Future<void> _toggleStatus(Offer offer, bool newStatus) async {
    setState(() => _updatingOfferId = offer.id);
    try {
      final updatedOffer = offer.copyWith(isActive: newStatus);
      await OfferService.instance.updateOffer(updatedOffer);
      _refreshOffers();
    } finally {
      if (mounted) setState(() => _updatingOfferId = null);
    }
  }

  Future<void> _bulkDeactivate(List<Offer> allOffers) async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deactivate ${_selectedIds.length} Offers?'),
        content: const Text('These offers will be marked as inactive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate All',
                style: TextStyle(color: Color(0xFFF59E0B))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var id in _selectedIds) {
        try {
          final offer = allOffers.firstWhere((o) => o.id == id);
          if (offer.isActive) await _toggleStatus(offer, false);
        } catch (_) {}
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  List<Offer> _filterOffers(List<Offer> offers) {
    var filtered = List<Offer>.from(offers);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((o) =>
              (o.code?.toLowerCase().contains(q) ?? false) ||
              (o.title.toLowerCase().contains(q)))
          .toList();
    }
    if (_showActiveOnly) filtered = filtered.where((o) => o.isActive).toList();
    if (_filterType == 'COUPON')
      filtered = filtered.where((o) => !o.isSale).toList();
    else if (_filterType == 'SALE')
      filtered = filtered.where((o) => o.isSale).toList();
    if (_sortByNewest) filtered.sort((a, b) => b.id.compareTo(a.id));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedIds.length} Selected')
            : const Text('Manage Offers'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                }),
              )
            : null,
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminOfferManageScreen()));
              },
              child: const Icon(Icons.add_rounded),
            ),
      body: StreamBuilder<List<Offer>>(
        key: ValueKey(_streamId),
        stream: _offersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return NetworkErrorState(
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load offers.'
                  : 'Error: ${snapshot.error}',
              onRetry: _refreshOffers,
            );
          }

          final allOffers = snapshot.data ?? [];
          final displayedOffers = _filterOffers(allOffers);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  // Search & Filter Header
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                          bottom: BorderSide(
                              color:
                                  colorScheme.outlineVariant.withOpacity(0.5))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by code or title...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Text(
                              "FILTER",
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip(
                                        'All',
                                        !_showActiveOnly,
                                        (v) => setState(
                                            () => _showActiveOnly = false)),
                                    const SizedBox(width: 8),
                                    _buildFilterChip(
                                        'Active Only',
                                        _showActiveOnly,
                                        (v) => setState(
                                            () => _showActiveOnly = true)),
                                    const SizedBox(width: 8),
                                    _buildTypeChip(
                                        'All',
                                        _filterType == 'ALL',
                                        () => setState(
                                            () => _filterType = 'ALL')),
                                    const SizedBox(width: 8),
                                    _buildTypeChip(
                                        'Coupons',
                                        _filterType == 'COUPON',
                                        () => setState(
                                            () => _filterType = 'COUPON')),
                                    const SizedBox(width: 8),
                                    _buildTypeChip(
                                        'Sales',
                                        _filterType == 'SALE',
                                        () => setState(
                                            () => _filterType = 'SALE')),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_isSelectionMode && _selectedIds.isNotEmpty)
                    Container(
                      width: double.infinity,
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            "${_selectedIds.length} SELECTED",
                            style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: colorScheme.primary),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.block_rounded, size: 14),
                            label: const Text("DEACTIVATE"),
                            onPressed: () => _bulkDeactivate(allOffers),
                          )
                        ],
                      ),
                    ),

                  Expanded(
                    child: displayedOffers.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              bottom:
                                  80 + MediaQuery.of(context).padding.bottom,
                            ),
                            itemCount: displayedOffers.length,
                            itemBuilder: (context, index) {
                              return _buildOfferRow(
                                  context, displayedOffers[index]);
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferRow(BuildContext context, Offer offer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedIds.contains(offer.id);
    final isInactive = !offer.isActive;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedIds.add(offer.id);
          });
        },
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected)
                _selectedIds.remove(offer.id);
              else
                _selectedIds.add(offer.id);
              if (_selectedIds.isEmpty) _isSelectionMode = false;
            });
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => AdminOfferManageScreen(offer: offer)));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.5))),
          ),
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    isSelected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isInactive
                      ? colorScheme.surfaceVariant
                      : colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  offer.isSale
                      ? Icons.flash_on_rounded
                      : Icons.local_offer_rounded,
                  color: isInactive
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.code ?? 'Flash Sale',
                      style: theme.textTheme.titleLarge?.copyWith(
                        // Increased from titleMedium
                        fontWeight: FontWeight.w700,
                        color: isInactive
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                        decoration:
                            isInactive ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      offer.title,
                      style:
                          theme.textTheme.bodyMedium // Increased from bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Status Toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_updatingOfferId == offer.id)
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: offer.isActive,
                        activeColor: colorScheme.primary,
                        onChanged: (v) => _toggleStatus(offer, v),
                      ),
                    ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: colorScheme.error.withOpacity(0.4), size: 16),
                    onPressed: () => _delete(offer.id),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined,
              size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: AppSpacing.md),
          Text('No offers created yet',
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool isSelected, Function(bool) onSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: colorScheme.primary.withOpacity(0.1),
      checkmarkColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.2)),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
    );
  }

  Widget _buildTypeChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: colorScheme.primary.withOpacity(0.1),
      backgroundColor: colorScheme.surface,
      side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.2)),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
    );
  }
}
