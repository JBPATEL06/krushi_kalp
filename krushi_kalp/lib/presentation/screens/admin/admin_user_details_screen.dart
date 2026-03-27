import 'package:flutter/material.dart';
import '../../../../data/services/admin_service.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_chat_detail_screen.dart';
import 'package:krushi_kalp/core/theme/app_spacing.dart';
import 'package:krushi_kalp/core/theme/app_radius.dart';
import 'package:krushi_kalp/presentation/widgets/common/modern_card.dart';
import '../../../../utils/error_utils.dart';
import '../../../utils/crashlytics_service.dart';

class AdminUserDetailsScreen extends StatefulWidget {
  final String userId;
  final String username;

  const AdminUserDetailsScreen({
    super.key,
    required this.userId,
    required this.username,
  });

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
    final theme = Theme.of(context);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
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
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'admin_user_details_screen');
        if (mounted) {
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  Future<void> _demoteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demote to Student?'),
        content: Text(
            'Are you sure you want to remove ${widget.username}\'s Admin privileges? They will become a regular Student.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B), // Amber
              foregroundColor: Colors.white,
            ),
            child: const Text('Demote'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AdminService.demoteToUser(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User demoted to Student successfully')),
          );
        }
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'admin_user_details_screen');
        if (mounted) {
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  Future<void> _deleteUser() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User Account?'),
        content: Text(
            'Are you sure you want to permanently delete ${widget.username}\'s account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
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
      } catch (e, stack) {
        CrashlyticsService.instance.recordError(e, stack, reason: 'admin_user_details_screen');
        if (mounted) {
          Navigator.pop(context); // Pop loading
          ErrorUtils.showError(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              _buildHeaderStream(),
              Container(
                color: colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  indicatorColor: colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Purchased Tests'),
                    Tab(text: 'Attempted Tests'),
                  ],
                ),
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
        ),
      ),
    );
  }

  Widget _buildHeaderStream() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<Map<String, dynamic>>(
      stream: AdminService.streamUserDetails(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: NetworkErrorState(
              compact: true,
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load user details.'
                  : 'Something went wrong.',
              onRetry: () => setState(() {}),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Center(child: CircularProgressIndicator()));
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      widget.username.isNotEmpty
                          ? widget.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(email,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.phone_rounded,
                                size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(phone,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text('Joined: $joined',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminChatDetailScreen(
                                    userId: widget.userId,
                                    userName: widget.username,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded,
                                size: 18),
                            label: const Text('Message User'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              side: BorderSide(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isStudent) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _promoteUser,
                        icon: const Icon(Icons.admin_panel_settings_rounded),
                        label: const Text('Make Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme.primary.withValues(alpha: 0.1),
                          foregroundColor: colorScheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteUser,
                        icon: const Icon(Icons.person_remove_rounded),
                        label: const Text('Delete User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme.error.withValues(alpha: 0.1),
                          foregroundColor: colorScheme.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded,
                          color: Color(0xFF10B981), size: 18),
                      SizedBox(width: 8),
                      Text('This user is an Admin',
                          style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _demoteUser,
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('Make Student'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          foregroundColor: const Color(0xFFF59E0B),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteUser,
                        icon: const Icon(Icons.person_remove_rounded),
                        label: const Text('Delete Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              colorScheme.error.withValues(alpha: 0.1),
                          foregroundColor: colorScheme.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPurchasesStream() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminService.streamUserOrders(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return NetworkErrorState(
            message: 'Something went wrong. Please try again.',
            onRetry: () => setState(() {}),
          );
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) return _buildEmptyState('No purchased tests found');

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final order = orders[index];
            final amount = order['total_amount'];
            final date = DateTime.parse(order['created_at']);

            return ModernCard(
              child: ListTile(
                leading: Icon(Icons.shopping_bag_rounded,
                    color: colorScheme.primary, size: 28),
                title: Text('Order #${order['order_id']}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('${date.day}/${date.month}/${date.year}',
                    style: theme.textTheme.bodySmall),
                trailing: Text(
                  '₹$amount',
                  style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttemptsStream() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AdminService.streamUserResults(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return NetworkErrorState(
            message: 'Something went wrong. Please try again.',
            onRetry: () => setState(() {}),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) return _buildEmptyState('No test attempts found');

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final result = results[index];
            final testName = result['mock_tests']?['title'] ?? 'Unknown Test';
            final score = result['score_obtained'];
            final total = result['mock_tests']?['total_marks'] ?? 0;
            final date = DateTime.parse(result['attempt_date']);

            return ModernCard(
              child: ListTile(
                leading: const Icon(Icons.assignment_rounded,
                    color: Color(0xFFF59E0B), size: 28),
                title: Text(testName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                subtitle: Text('${date.day}/${date.month}/${date.year}',
                    style: theme.textTheme.bodySmall),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    '$score / $total',
                    style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text(message, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
