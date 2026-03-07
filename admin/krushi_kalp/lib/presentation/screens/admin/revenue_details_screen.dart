import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/admin_service.dart';
import 'package:krushi_kalp_admin/core/theme/app_spacing.dart';
import 'package:krushi_kalp_admin/core/theme/app_radius.dart';

class RevenueDetailsScreen extends StatefulWidget {
  const RevenueDetailsScreen({super.key});

  @override
  State<RevenueDetailsScreen> createState() => _RevenueDetailsScreenState();
}

class _RevenueDetailsScreenState extends State<RevenueDetailsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String _selectedFilter = 'All'; // All, Yearly, Monthly, Today

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminService.fetchAllOrdersWithDetails();
      if (mounted) {
        setState(() {
          _orders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchData,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final now = DateTime.now();
    final List<Map<String, dynamic>> filteredOrders = _orders.where((order) {
      if (_selectedFilter == 'All') return true;
      if (order['created_at'] == null) return false;

      final date = DateTime.parse(order['created_at']).toUtc().toLocal();
      if (_selectedFilter == 'Today') {
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      } else if (_selectedFilter == 'Monthly') {
        return date.year == now.year && date.month == now.month;
      } else if (_selectedFilter == 'Yearly') {
        return date.year == now.year;
      }
      return true;
    }).toList();

    final double totalRevenue = filteredOrders.fold(0.0, (sum, item) {
      return sum + ((item['total_amount'] as num?)?.toDouble() ?? 0.0);
    });

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Revenue Insights'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                      bottom: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.5))),
                ),
                child: Column(
                  children: [
                    Text(
                      'TOTAL REVENUE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '₹${totalRevenue.toStringAsFixed(2)}',
                        style: theme.textTheme.displayLarge?.copyWith(
                          // Increased from displayMedium
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF10B981), // Emerald
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${filteredOrders.length} SUCCESSFUL SALES',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Filter Row
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
                                _buildFilterChip('All'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Today'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Monthly'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Yearly'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transaction List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              return _buildOrderRow(filteredOrders[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = order['users'];
    final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final String dateStr = order['created_at'] != null
        ? DateFormat('MMM dd • hh:mm a')
            .format(DateTime.parse(order['created_at']).toUtc().toLocal())
        : 'Unknown Date';
    final String username =
        user != null ? (user['username'] ?? 'Unknown') : 'Unknown User';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showOrderDetailsDialog(order),
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
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded,
                    color: colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 16),
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: theme
                          .textTheme.titleLarge // Increased from titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        // Increased from bodySmall
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+ ₹${amount.toStringAsFixed(2)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = order['users'];
    final offer = order['offers'];
    final items = order['order_items'] as List<dynamic>? ?? [];
    final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final String dateStr = order['created_at'] != null
        ? DateFormat('MMM dd, yyyy • hh:mm a')
            .format(DateTime.parse(order['created_at']).toUtc().toLocal())
        : 'Unknown Date';

    final bool isDirect = offer == null;
    String offerText = 'Direct Checkout';
    String discountStr = '';

    if (!isDirect) {
      final code = offer['code'] ?? 'Sale';
      final val = offer['discount_value'];
      final type = offer['discount_type'];
      if (val != null) {
        discountStr = type == 'PERCENTAGE' ? '${val}% OFF' : '₹${val} OFF';
      }
      offerText =
          (offer['code'] == null) ? 'Store Sale Applied' : 'Coupon Code: $code';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transaction Details',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                  style: IconButton.styleFrom(
                      backgroundColor:
                          colorScheme.surfaceVariant.withOpacity(0.3)),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow(context, Icons.person_rounded, 'CUSTOMER',
                '${user?['username'] ?? 'Unknown'}\n${user?['email'] ?? ''}'),
            const SizedBox(height: AppSpacing.md),
            _buildDetailRow(
                context, Icons.calendar_today_rounded, 'DATE & TIME', dateStr),
            const SizedBox(height: AppSpacing.md),
            if (!isDirect) ...[
              _buildDetailRow(
                context,
                Icons.local_offer_rounded,
                'OFFER APPLIED',
                offerText,
                extra: discountStr.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: colorScheme.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(discountStr,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.tertiary,
                                fontWeight: FontWeight.bold)),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('PURCHASED ITEMS',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(height: 16),
                        Builder(builder: (context) {
                          final item = items[i];
                          final mockTest = item['mock_tests'];
                          final resource = item['resources'];
                          String title = 'Unknown Item';
                          if (mockTest != null) {
                            title = '${mockTest['title']}';
                          } else if (resource != null) {
                            title = '${resource['title']}';
                          }
                          final double price =
                              (item['price_at_purchase'] as num?)?.toDouble() ??
                                  0.0;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹${price.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Paid',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('₹${amount.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.tertiary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) setState(() => _selectedFilter = label);
      },
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.background,
      labelStyle: TextStyle(
        color:
            isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.2)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value,
      {Widget? extra}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 20, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant, letterSpacing: 1.1)),
              const SizedBox(height: 2),
              Text(value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              if (extra != null) extra,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: AppSpacing.md),
          Text('No transactions found',
              style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
