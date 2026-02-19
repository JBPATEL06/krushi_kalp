import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/services/admin_service.dart';

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
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
    // Calculate total revenue from fetched data for consistency
    // 1. Filter Logic
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

    // 2. Calculate Totals based on Filtered Data
    final double totalRevenue = filteredOrders.fold(0.0, (sum, item) {
      return sum + ((item['total_amount'] as num?)?.toDouble() ?? 0.0);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Revenue Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  'Total Revenue',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${totalRevenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${filteredOrders.length} Successful Transactions',
                  style: TextStyle(
                      color: Colors.blueGrey[400], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
              ],
            ),
          ),
          const Divider(height: 1),

          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No transactions found',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderCard(order);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final user = order['users'];
    final double amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final String dateStr = order['created_at'] != null
        ? DateFormat('MMM dd, yyyy • hh:mm a')
            .format(DateTime.parse(order['created_at']).toUtc().toLocal())
        : 'Unknown Date';
    final String username =
        user != null ? (user['username'] ?? 'Unknown') : 'Unknown User';
    final String email = user != null ? (user['email'] ?? '') : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showOrderDetailsDialog(order),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[50],
                  child: Icon(Icons.receipt_outlined,
                      color: Colors.blue[700], size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(email,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500])),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+ ₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order) {
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
      final code = offer['code'] ?? 'Unknown';
      final val = offer['discount_value'];
      final type = offer['discount_type'];

      if (val != null) {
        discountStr = type == 'PERCENTAGE' ? '${val}% OFF' : '₹${val} OFF';
      }
      offerText = 'Code: $code';
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transaction Details',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // Customer Info
              _buildDetailRow(Icons.person, 'Customer',
                  '${user?['username'] ?? 'Unknown'}\n${user?['email'] ?? ''}'),
              const SizedBox(height: 12),

              // Date
              _buildDetailRow(Icons.calendar_today, 'Date', dateStr),
              const SizedBox(height: 12),

              // Offer Info
              if (!isDirect) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.local_offer, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Offer Applied',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(offerText,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          if (discountStr.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(discountStr,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
              ],

              const Text('Purchased Items',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Column(
                    children: items.map((item) {
                      final mockTest = item['mock_tests'];
                      final resource = item['resources'];

                      String title = 'Unknown Item';
                      if (mockTest != null) {
                        title = 'Test: ${mockTest['title'] ?? 'Unnamed'}';
                      } else if (resource != null) {
                        final type = resource['type'] ?? 'Resource';
                        title = '$type: ${resource['title'] ?? 'Unnamed'}';
                      } else {
                        title =
                            'Item #${item['test_id'] ?? item['resource_id'] ?? 'null'}';
                      }

                      final double price =
                          (item['price_at_purchase'] as num?)?.toDouble() ??
                              0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text('• $title',
                                    style: const TextStyle(fontSize: 14))),
                            Text('₹$price',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Paid',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
      selectedColor: Colors.green,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
