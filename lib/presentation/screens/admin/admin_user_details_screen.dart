import 'package:flutter/material.dart';
import '../../../../data/services/admin_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/network_error_state.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final String userId;
  final String username;

  const AdminUserDetailsScreen(
      {super.key, required this.userId, required this.username});

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _promoteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote to Admin?'),
        content: Text(
            'Are you sure you want to make ${widget.username} an Admin? This will give them full access to the admin panel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Promote'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminService.promoteToAdmin(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User promoted to Admin successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error promoting user: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User Account?'),
        content: Text(
            'Are you sure you want to permanently delete ${widget.username}\'s account? This action cannot be undone and will remove all their data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        await AdminService.deleteUser(widget.userId);

        if (mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully')),
          );
          Navigator.pop(context); // Go back to list
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting user: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      body: Column(
        children: [
          _buildHeaderStream(),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: const [
              Tab(text: 'Purchased Tests'),
              Tab(text: 'Attempted Tests'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPurchasesStream(),
                _buildAttemptsStream(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStream() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: AdminService.streamUserDetails(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: NetworkErrorState(
              compact: true,
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load user details.'
                  : 'Error: ${snapshot.error}',
              onRetry: () => setState(() {}),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
              padding: EdgeInsets.all(20), child: CircularProgressIndicator());
        }

        final user = snapshot.data!;
        final email = user['email'] ?? 'No Email';
        final phone = user['phonenumber'] ?? 'No Phone';
        final role = (user['role'] ?? 'Student').toString();
        final isStudent = role.toLowerCase() != 'admin';

        String joined = 'Unknown';
        if (user['created_at'] != null) {
          final date = DateTime.tryParse(user['created_at']);
          if (date != null) {
            joined = '${date.day}/${date.month}/${date.year}';
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(
                      widget.username.isNotEmpty
                          ? widget.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(email,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(phone,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('Joined: $joined',
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isStudent) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _promoteUser,
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Make Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          foregroundColor: Theme.of(context).primaryColor,
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteUser,
                        icon: const Icon(Icons.person_remove),
                        label: const Text('Delete User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text('This user is an Admin',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPurchasesStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminService.streamUserOrders(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return NetworkErrorState(
            message: isNetworkError(snapshot.error)
                ? 'Unable to load purchases.'
                : 'Error: ${snapshot.error}',
            onRetry: () => setState(() {}),
          );
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) return _buildEmptyState('No purchased tests found');

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            final amount = order['total_amount'];
            final date = DateTime.parse(order['created_at']);

            return AppCard(
              child: ListTile(
                leading: Icon(Icons.shopping_bag,
                    color: Theme.of(context).primaryColor),
                title: Text('Order #${order['order_id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${date.day}/${date.month}/${date.year}'),
                trailing: Text(
                  '₹$amount',
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttemptsStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminService.streamUserResults(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return NetworkErrorState(
            message: isNetworkError(snapshot.error)
                ? 'Unable to load test attempts.'
                : 'Error: ${snapshot.error}',
            onRetry: () => setState(() {}),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) return _buildEmptyState('No test attempts found');

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final result = results[index];
            final testName = result['mock_tests']?['title'] ?? 'Unknown Test';
            final score = result['score_obtained'];
            final total = result['mock_tests']?['total_marks'] ?? 0;
            final date = DateTime.parse(result['attempt_date']);

            return AppCard(
              child: ListTile(
                leading: const Icon(Icons.assignment, color: Colors.orange),
                title: Text(testName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${date.day}/${date.month}/${date.year}'),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$score / $total',
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
