import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/admin_service.dart';
import '../../widgets/common/network_error_state.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});

  @override
  State<AdminOrderListScreen> createState() => _AdminOrderListScreenState();
}

class _AdminOrderListScreenState extends State<AdminOrderListScreen> {
  late Stream<List<Map<String, dynamic>>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = AdminService.streamAllOrders();
  }

  // ─── Detail Dialog ──────────────────────────────────────────────────────────

  Future<void> _onRowTap(Map<String, dynamic> basicOrder) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not load transaction details.'),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    _showOrderDetailsDialog(order);
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final user = order['users'] as Map<String, dynamic>?;
    final offer = order['offers'] as Map<String, dynamic>?;
    final items = order['order_items'] as List<dynamic>? ?? [];
    final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final double discountAmount =
        (order['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final String paymentId = order['payment_id'] as String? ?? '—';
    final String orderId = order['order_id'] as String? ?? '—';
    final String dateStr = order['created_at'] != null
        ? DateFormat('MMM dd, yyyy • hh:mm a')
            .format(DateTime.parse(order['created_at']).toUtc().toLocal())
        : 'Unknown Date';

    final String userName = user?['username'] ?? 'Unknown';
    final String userEmail = user?['email'] ?? '';
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
        discountLabel = (type == 'PERCENTAGE') ? '${val}% OFF' : '₹${val} OFF';
      }
    }

    final emerald = colorScheme.tertiary;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
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
                          color: emerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(Icons.receipt_long_rounded,
                            color: emerald, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction Details',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              dateStr,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        icon: Icon(Icons.close_rounded,
                            color: colorScheme.onSurfaceVariant),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              colorScheme.surfaceVariant.withOpacity(0.4),
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
                              color: emerald.withOpacity(0.1),
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
                        color: colorScheme.surfaceVariant.withOpacity(0.25),
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
                                      final String title = mockTest != null
                                          ? (mockTest['title'] ?? 'Mock Test')
                                          : resource != null
                                              ? (resource['title'] ??
                                                  'Resource')
                                              : 'Unknown Item';
                                      final String type = mockTest != null
                                          ? 'Test'
                                          : (resource?['type'] ?? 'Resource');
                                      final double price =
                                          (item['price_at_purchase'] as num?)
                                                  ?.toDouble() ??
                                              0.0;
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
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                type.toUpperCase(),
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 8,
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
                                              '₹${price.toStringAsFixed(0)}',
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
                  if (discountAmount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                        Text(
                          '-₹${discountAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: emerald, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid',
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

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _ordersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return NetworkErrorState(
                  message: isNetworkError(snapshot.error)
                      ? 'Unable to load orders. Check your connection.'
                      : 'Error: ${snapshot.error}',
                  onRetry: () => setState(() {
                    _ordersStream = AdminService.streamAllOrders();
                  }),
                );
              }

              final orders = snapshot.data ?? [];

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildSectionHeader(context, 'TRANSACTION HISTORY'),
                        const Spacer(),
                        Text(
                          '${orders.length} Total',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: orders.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _buildOrderRow(context, order);
                            },
                          ),
                  ),
                ],
              );
            },
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
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 1.5,
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
              size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.2)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No transactions yet',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final emerald = colorScheme.tertiary;

    final amount = (order['total_amount'] as num).toDouble();
    final dateStr = order['created_at'] as String;
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    final formattedDate =
        DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal());

    final user = order['users'] as Map<String, dynamic>?;
    final userEmail = user?['email'] ?? 'Unknown User';
    final userName = user?['username'] ?? 'User';

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: () => _onRowTap(order),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5)),
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
                    color: emerald.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_rounded, color: emerald, size: 24),
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
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                          fontSize: 10,
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
                      '₹${amount.toStringAsFixed(0)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: emerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SUCCESS',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: emerald,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.3),
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
            size: 18, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
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
