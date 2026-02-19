import 'package:flutter/material.dart';
import '../../../../data/services/admin_service.dart';
import '../../../../utils/network_utils.dart'; // Import NetworkUtils

import 'admin_offer_list_screen.dart';
import 'admin_chat_list_screen.dart';
import 'admin_profile_screen.dart';
import 'revenue_details_screen.dart';
import 'resources/admin_resources_dashboard.dart';
import 'admin_store_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Streams to control refreshing
  late Stream<List<Map<String, dynamic>>> _topTestsStream;
  late Stream<List<Map<String, dynamic>>> _topUsersStream;
  Key _refreshKey = UniqueKey(); // Force rebuild if needed

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _topTestsStream = AdminService.streamTopTests();
    _topUsersStream = AdminService.streamTopUsers();
  }

  Future<void> _onRefresh() async {
    // Artificial delay to show the spinner (streams update real-time anyway, but this forces a re-subscription/check)
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _initStreams();
        _refreshKey = UniqueKey();
      });
    }
  }

  Widget _buildQuickActionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
              );
            },
            icon: const Icon(Icons.person)),
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminChatListScreen()),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.black),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          key: _refreshKey,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Management',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Manage Store',
                      icon: Icons.storefront_rounded,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminStoreScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Manage Offers',
                      icon: Icons.local_offer_rounded,
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminOfferListScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Added space for the new row
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Revenue',
                      icon: Icons.attach_money,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RevenueDetailsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      context,
                      title: 'Resources',
                      icon: Icons.library_books,
                      color: Colors.deepPurple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminResourcesDashboard(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Top Tests Stream
              const Text(
                'Top Performing Mock Tests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _topTestsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    if (!NetworkUtils.isNetworkError(snapshot.error)) {
                      debugPrint("Stream Error (Tests): ${snapshot.error}");
                    }
                    // Graceful Fallback
                    return _buildErrorState("Unable to load tests.");
                  }
                  final tests = snapshot.data ?? [];
                  return _buildTopTestsList(tests);
                },
              ),

              const SizedBox(height: 32),

              // Top Users Stream
              const Text(
                'Top Performing Users',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _topUsersStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    if (!NetworkUtils.isNetworkError(snapshot.error)) {
                      debugPrint("Stream Error (Users): ${snapshot.error}");
                    }
                    return _buildErrorState("Unable to load users.");
                  }
                  final users = snapshot.data ?? [];
                  return _buildTopUsersList(users);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50], // Light red background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red[300]),
            const SizedBox(width: 8),
            Text(message, style: TextStyle(color: Colors.red[800])),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTestsList(List<Map<String, dynamic>> tests) {
    if (tests.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text('No data yet', style: TextStyle(color: Colors.grey[400])),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tests.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final test = tests[index];
          return Container(
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.blue.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: test['image_url'] != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(18)),
                            child: Image.network(
                              test['image_url'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback icon on error
                                return Center(
                                    child: Icon(Icons.broken_image_rounded,
                                        color: Colors.blue[300], size: 40));
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(Icons.book,
                                color: Colors.blue[300], size: 40)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          test['title'] ?? 'Untitled',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                              height: 1.2),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${test['sales'] ?? 0} Sold',
                                style: TextStyle(
                                    color: Colors.blue[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                            Text('₹${test['price'] ?? 0}',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopUsersList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: const Center(
            child: Text('No active users found.',
                style: TextStyle(color: Colors.grey))),
      );
    }

    final displayUsers = users.take(3).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = displayUsers[index];
        final totalMax = user['totalMax'] as double;
        final totalScore = user['totalScore'] as double;
        final percentage = totalMax > 0 ? (totalScore / totalMax) * 100 : 0.0;
        final firstChar = (user['username'] as String).isNotEmpty
            ? (user['username'] as String)[0].toUpperCase()
            : '?';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.blue.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue[50],
              child: Text(firstChar,
                  style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
            ),
            title: Text(user['username'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF0F172A))),
                const SizedBox(width: 4),
                Icon(Icons.emoji_events_rounded,
                    size: 18, color: Colors.amber[600]),
              ],
            ),
          ),
        );
      },
    );
  }
}
