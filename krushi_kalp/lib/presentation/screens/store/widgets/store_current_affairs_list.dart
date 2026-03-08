import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/resource.dart';
import '../../../../core/theme/app_spacing.dart';

class StoreCurrentAffairsList extends StatelessWidget {
  final List<Resource> items;
  final Set<int> purchasedIds; // NEW
  final Function(Resource) onTap;

  const StoreCurrentAffairsList({
    super.key,
    required this.items,
    required this.purchasedIds, // Force update
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: Text("No current affairs updates.")),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          final theme = Theme.of(context);
          return Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                leading: Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(Icons.newspaper,
                          color: theme.colorScheme.primary),
                    ),
                    if (purchasedIds.contains(item.id))
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              size: 8, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                title: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (item.description != null)
                      Text(item.description!,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(item.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!purchasedIds.contains(item.id)) ...[
                      if (item.mrp != null && item.mrp! > item.price)
                        Text(
                          '₹${item.mrp!.toStringAsFixed(0)}',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      Text(
                        item.price <= 0
                            ? 'Free'
                            : '₹${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: item.price <= 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ] else
                      Icon(Icons.check_circle,
                          color: theme.colorScheme.primary),
                  ],
                ),
                onTap: () => onTap(item),
              ),
            ),
          );
        },
        childCount: items.length,
      ),
    );
  }
}
