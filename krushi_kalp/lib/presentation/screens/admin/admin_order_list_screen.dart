import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../widgets/common/debounced_search_bar.dart';
import 'package:krushi_kalp/utils/responsive.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/admin_service.dart';
import '../../widgets/common/network_error_state.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../../utils/error_utils.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  static const _pageSize = 20;
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await AdminService.fetchPaginatedOrders(
        offset: pageKey,
        limit: _pageSize,
        searchQuery: _searchQuery,
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _onSearch(String query) {
    _searchQuery = query;
    _pagingController.refresh();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  // ─── Detail Dialog ──────────────────────────────────────────────────────────

  Future<void> _onRowTap(Map<String, dynamic> basicOrder) async {
    final orderId = basicOrder['order_id'] as String?;
    if (orderId == null) return;

    // Show loading dialog while fetching full details
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final order = await AdminService.fetchOrderById(orderId);

    if (!mounted) return;
    Navigator.pop(context); // Close loader

    if (order == null) {
      ErrorUtils.showError(context, 'Could not load transaction details.');
      return;
    }

    _showOrderDetailsDialog(order);
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const emerald = Color(0xFF10B981);

    final user = order['users'] as Map<String, dynamic>?;
    final offer = order['offers'] as Map<String, dynamic>?;
    final items = order['order_items'] as List<dynamic>? ?? [];
    final double amount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
    final double discountAmount =
        double.tryParse(order['discount_amount']?.toString() ?? '0') ?? 0.0;
    final String paymentId = order['payment_id'] as String? ?? '—';
    final String orderId = order['order_id'] as String? ?? '—';
    final String dateStr = order['created_at'] != null
        ? DateFormat('MMM dd, yyyy • hh:mm a')
            .format(DateTime.parse(order['created_at']).toLocal())
        : 'Unknown Date';

    final String userEmail = user?['email'] ?? '';
    String userName = user?['username'] ?? '';
    if (userName.isEmpty || userName == 'User' || userName == 'Legacy User') {
      userName = userEmail.isNotEmpty ? userEmail.split('@')[0] : 'Customer';
    }

    final String userPhone = user?['phonenumber'] ?? '—';

    // Offer info
    String offerLabel = 'No Offer Applied';
    String discountLabel = '';
    bool hasOffer = offer != null;
    if (hasOffer) {
      final code = offer['code'];
      final val = offer['discount_value'];
      final type = offer['discount_type'];
      offerLabel = code != null ? 'Coupon: $code' : 'Sale Offer';
      if (val != null) {
        discountLabel = (type == 'PERCENTAGE') ? '$val% OFF' : '₹$val OFF';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        insetPadding: EdgeInsets.symmetric(
            horizontal: context.w(20), vertical: context.h(40)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.w(520)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: emerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(Icons.receipt_long_rounded,
                            color: emerald, size: context.sp(22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction Details',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.sp(20)),
                            ),
                            Text(
                              dateStr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: context.sp(11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        iconSize: context.sp(20),
                        icon: Icon(Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: context.sp(20)),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),

                  // ── Customer ────────────────────────────────────────
                  _DialogSection(
                    icon: Icons.person_rounded,
                    label: 'CUSTOMER',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (userEmail.isNotEmpty)
                          Text(userEmail,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                        if (userPhone != '—')
                          Text(userPhone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── IDs Section ─────────────────────────────────────
                  _DialogSection(
                    icon: Icons.tag_rounded,
                    label: 'ORDER INFO',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IdChip(label: 'Order ID', value: orderId),
                        const SizedBox(height: 6),
                        _IdChip(label: 'Payment ID', value: paymentId),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Offer ───────────────────────────────────────────
                  _DialogSection(
                    icon: Icons.local_offer_rounded,
                    label: 'OFFER',
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            offerLabel,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (discountLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              discountLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: emerald, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Items ───────────────────────────────────────────
                  _DialogSection(
                    icon: Icons.shopping_bag_rounded,
                    label: 'PURCHASED ITEMS (${items.length})',
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'No items found',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0; i < items.length; i++) ...[
                                    if (i > 0) const Divider(height: 1),
                                    Builder(builder: (context) {
                                      final item =
                                          items[i] as Map<String, dynamic>;
                                      final mockTest = item['mock_tests']
                                          as Map<String, dynamic>?;
                                      final resource = item['resources']
                                          as Map<String, dynamic>?;

                                      String title = 'Unknown Item';
                                      String typeLabel = 'Item';
                                      double priceAtPurchase = _parseNum(item['price_at_purchase']);

                                      if (mockTest != null) {
                                        title = mockTest['title'] ?? 'Untitled Test';
                                        typeLabel = 'Test';
                                      } else if (resource != null) {
                                        title = resource['title'] ?? 'Untitled Resource';
                                        typeLabel = (resource['type'] ?? 'Resource').toString();
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                typeLabel.toUpperCase(),
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      context.sp(8),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '₹${priceAtPurchase.toStringAsFixed(0)}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Total ───────────────────────────────────────────
                  Builder(builder: (context) {
                    // REFINED MATH (Per User Instruction):
                    final double netPaid = amount;
                    final double actualDiscount = discountAmount;
                    final double grossSubtotal = netPaid + actualDiscount;
                    
                    final String? offerCode = order['offer_code']?.toString();
                    final offer = order['offers'] as Map?;
                    String discountLabel = 'Discount';
                    if (offerCode != null) {
                      final percent = offer?['discount_percent'];
                      discountLabel = percent != null ? 'Discount ($offerCode $percent% OFF)' : 'Discount ($offerCode)';
                    }

                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                            Text(
                              '₹${grossSubtotal.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (actualDiscount > 0) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(discountLabel,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant)),
                              Text(
                                '-₹${actualDiscount.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: emerald, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    );
                  }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Paid',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${amount.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: emerald,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const emerald = Color(0xFF10B981); // Emerald Green

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildSectionHeader(context, 'TRANSACTION HISTORY'),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DebouncedSearchBar(
                      hintText: 'Search by Order ID or Payment ID...',
                      onChanged: _onSearch,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _pagingController.refresh(),
                  child: PagedListView<int, Map<String, dynamic>>(
                    pagingController: _pagingController,
                    padding: EdgeInsets.zero,
                    builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                      itemBuilder: (context, order, index) {
                        return _buildOrderRow(context, order, theme, colorScheme, emerald);
                      },
                      firstPageErrorIndicatorBuilder: (context) => NetworkErrorState(
                        message: 'Failed to load orders',
                        onRetry: () => _pagingController.refresh(),
                      ),
                      noItemsFoundIndicatorBuilder: (context) => _buildEmptyState(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(BuildContext context, Map<String, dynamic> order,
      ThemeData theme, ColorScheme colorScheme, Color emerald) {
    final amount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
    final dateStr = order['created_at'] as String;
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final formattedDate =
        DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal());

    final user = order['users'] as Map<String, dynamic>?;
    final String userEmail = user?['email'] ?? '';
    String userName = user?['username'] ?? '';
    
    if (userName.isEmpty || userName == 'User' || userName == 'Legacy User') {
      userName = userEmail.isNotEmpty ? userEmail.split('@')[0] : 'Customer';
    }
    if (userName.isEmpty) userName = 'Customer';

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: () => _onRowTap(order),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_rounded,
                      color: emerald, size: context.sp(24)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: context.sp(12),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                          fontSize: context.sp(10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        fontSize: context.sp(22),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SUCCESS',
                        style: TextStyle(
                          fontSize: context.sp(8),
                          fontWeight: FontWeight.w900,
                          color: emerald,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _parseNum(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final String str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    final cleanStr = str.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleanStr) ?? 0.0;
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _DialogSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _DialogSection({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: context.sp(18),
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _IdChip extends StatelessWidget {
  final String label;
  final String value;

  const _IdChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: colorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
