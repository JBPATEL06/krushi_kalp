import 'package:flutter/material.dart';
import '../../../../data/services/admin_service.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_user_details_screen.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  String _selectedFilter = 'All'; // All, New, Active
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> allUsers) {
    final now = DateTime.now();

    return allUsers.where((user) {
      // 1. Search Filter
      final username = (user['username'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final matchesSearch = username.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      // 2. Chip Filter
      if (_selectedFilter == 'New') {
        if (user['created_at'] == null) return false;
        final createdAt = DateTime.tryParse(user['created_at']);
        if (createdAt == null) return false;
        final difference = now.difference(createdAt).inDays;
        return difference <= 30;
      } else if (_selectedFilter == 'Active') {
        if (user['last_active'] == null) return false;
        final lastActive = DateTime.tryParse(user['last_active']);
        if (lastActive == null) return false;
        final difference = now.difference(lastActive).inDays;
        return difference <= 15;
      }

      return true; // 'All'
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('All Users',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: AdminService.streamUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return NetworkErrorState(
              message: isNetworkError(snapshot.error)
                  ? 'Unable to load users. Check your connection.'
                  : 'Error: ${snapshot.error}',
              onRetry: () => setState(() {}),
            );
          }

          final allUsers = snapshot.data ?? [];
          final filteredUsers = _applyFilters(allUsers);

          return Column(
            children: [
              // Search & Filters Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.blueGrey),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          const SizedBox(width: 8),
                          _buildFilterChip('New'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Active'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Users List
              Expanded(
                child: filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.grey[300]!,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final username = user['username'] ?? 'Unknown';
    final firstChar = username.isNotEmpty ? username[0].toUpperCase() : '?';

    // Status logic
    bool isNew = false;
    if (user['created_at'] != null) {
      final createdAt = DateTime.tryParse(user['created_at']);
      if (createdAt != null) {
        isNew = DateTime.now().difference(createdAt).inDays <= 30;
      }
    }

    bool isActive = false;
    if (user['last_active'] != null) {
      final lastActive = DateTime.tryParse(user['last_active']);
      if (lastActive != null) {
        isActive = DateTime.now().difference(lastActive).inDays <= 15;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminUserDetailsScreen(
                userId: user['id'],
                username: username,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  firstChar,
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 8),
                          _buildStatusBadge('NEW', Colors.purple),
                        ],
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          _buildStatusBadge('ACTIVE', Colors.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(user['email'] ?? 'No Email',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 13)),
                    if (user['last_active'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.history,
                                size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              'Last Active: ${_formatDate(user['last_active'])}',
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color[100]!),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color[700], fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
