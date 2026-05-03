import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/offer_notifier.dart';

import 'package:krushi_kalp/utils/responsive.dart';
import '../../../../domain/models/offer.dart';
import '../../../../data/services/offer_service.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_offer_manage_screen.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../../utils/error_utils.dart';
import '../../../utils/crashlytics_service.dart';

class AdminOfferListScreen extends ConsumerStatefulWidget {
  final bool showOnlyActive;
  const AdminOfferListScreen({super.key, this.showOnlyActive = false});

  @override
  ConsumerState<AdminOfferListScreen> createState() => _AdminOfferListScreenState();
}

class _AdminOfferListScreenState extends ConsumerState<AdminOfferListScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  int? _updatingOfferId;

  @override
  void initState() {
    super.initState();
    _refreshOffers();
  }

  void _refreshOffers() {
    ref.read(offerProvider.notifier).fetchActiveOffers();
  }

  @override
  void dispose() {
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
            _refreshOffers(); 
          }
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'admin_offer_list_screen_delete');
        if (mounted) ErrorUtils.showError(context, e.toString());
      }
    }
  }

  Future<void> _toggleStatus(Offer offer, bool active) async {
    setState(() => _updatingOfferId = offer.id);
    try {
      await OfferService.instance.updateOffer(offer.copyWith(isActive: active));
      ref.read(offerProvider.notifier).fetchActiveOffers(forceRefresh: true);
    } catch (e, stack) {
      CrashlyticsService.instance.recordError(e, stack, reason: 'admin_offer_list_toggle');
      if (mounted) ErrorUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _updatingOfferId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final offerState = ref.watch(offerProvider);

    if (offerState.isLoading && offerState.activeOffers.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (offerState.errorMessage.isNotEmpty && offerState.activeOffers.isEmpty) {
      return Scaffold(
        body: NetworkErrorState(
          onRetry: _refreshOffers,
        ),
      );
    }

    final offers = offerState.activeOffers;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshOffers,
          ),
        ],
      ),
      body: offers.isEmpty ? _buildEmptyState() : ListView.builder(
        itemCount: offers.length,
        itemBuilder: (context, index) {
          final offer = offers[index];
          final isSelected = _selectedIds.contains(offer.id);
          return _buildOfferItem(context, theme, colorScheme, offer, isSelected);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminOfferManageScreen()),
        ),
        label: const Text('NEW OFFER'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOfferItem(BuildContext context, ThemeData theme, ColorScheme colorScheme, Offer offer, bool isSelected) {
    final isInactive = !offer.isActive;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.1)
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
              if (isSelected) {
                _selectedIds.remove(offer.id);
              } else {
                _selectedIds.add(offer.id);
              }
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
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
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
                    size: context.sp(20),
                  ),
                ),
              // Icon
              Container(
                width: context.sp(48),
                height: context.sp(48),
                decoration: BoxDecoration(
                  color: isInactive
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  offer.isSale
                      ? Icons.flash_on_rounded
                      : Icons.local_offer_rounded,
                  color: isInactive
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                  size: context.sp(24),
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
                        fontWeight: FontWeight.w700,
                        fontSize: context.sp(18),
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: context.sp(14)),
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
                        activeThumbColor: colorScheme.primary,
                        onChanged: (v) => _toggleStatus(offer, v),
                      ),
                    ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: colorScheme.error.withValues(alpha: 0.4),
                        size: context.sp(16)),
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_offer_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: AppSpacing.md),
                Text('No offers matching criteria',
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
