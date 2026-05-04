import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:easy_debounce/easy_debounce.dart';
import '../../../../data/services/admin_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../utils/error_utils.dart';

class AdminGrantAccessScreen extends ConsumerStatefulWidget {
  // User Mode parameters
  final String? userId;
  final String? username;
  final String? initialItemType;
  final int? initialItemId;
  final String? initialResourceCategory;

  // Item Mode parameters
  final String? itemType;
  final int? itemId;
  final String? itemTitle;
  final Map<String, dynamic>? itemSnapshot;
  final bool isAuditMode;

  const AdminGrantAccessScreen({
    super.key,
    this.userId,
    this.username,
    this.initialItemType,
    this.initialItemId,
    this.initialResourceCategory,
    this.itemType,
    this.itemId,
    this.itemTitle,
    this.itemSnapshot,
    this.isAuditMode = false,
  });

  @override
  ConsumerState<AdminGrantAccessScreen> createState() => _AdminGrantAccessScreenState();
}

class _AdminGrantAccessScreenState extends ConsumerState<AdminGrantAccessScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  static const int _pageSize = 20;

  // Data (User Mode)
  Map<String, Set<int>> _existingAccess = {};

  // Pagination (User Mode - Items)
  final PagingController<int, Map<String, dynamic>> _testsPagingController = PagingController(firstPageKey: 0);
  final PagingController<int, Map<String, dynamic>> _ebooksPagingController = PagingController(firstPageKey: 0);
  final PagingController<int, Map<String, dynamic>> _pyqsPagingController = PagingController(firstPageKey: 0);
  final PagingController<int, Map<String, dynamic>> _gkPagingController = PagingController(firstPageKey: 0);
  final PagingController<int, Map<String, dynamic>> _studyMaterialPagingController = PagingController(firstPageKey: 0);

  // Pagination (Item Mode - Users)
  final PagingController<int, Map<String, dynamic>> _pagingController = PagingController(firstPageKey: 0);
  Set<String> _existingUserAccess = {};

  // Pagination (Audit Mode)
  final PagingController<int, Map<String, dynamic>> _auditPaidPagingController = PagingController(firstPageKey: 0);
  final PagingController<int, Map<String, dynamic>> _auditClaimedPagingController = PagingController(firstPageKey: 0);
  final PagingController<int, Map<String, dynamic>> _auditManualPagingController = PagingController(firstPageKey: 0);

  // Selection states
  final Set<String> _selectedItems = {}; // Format: "type_id" e.g., "test_123" or "resource_456"
  final Set<String> _selectedUserIds = {}; // Format: "user_id"

  bool get _isUserMode => widget.userId != null;
  bool get _isItemMode => widget.itemId != null && widget.itemType != null;

  @override
  void initState() {
    super.initState();
    if (_isUserMode) {
      _tabController = TabController(length: 5, vsync: this);
      
      // Add pagination listeners for User Mode
      _testsPagingController.addPageRequestListener((pageKey) => _fetchTestsPage(pageKey));
      _ebooksPagingController.addPageRequestListener((pageKey) => _fetchResourcesPage(pageKey, 'ebook', _ebooksPagingController));
      _pyqsPagingController.addPageRequestListener((pageKey) => _fetchResourcesPage(pageKey, 'pyq', _pyqsPagingController));
      _gkPagingController.addPageRequestListener((pageKey) => _fetchResourcesPage(pageKey, 'current_affair', _gkPagingController));
      _studyMaterialPagingController.addPageRequestListener((pageKey) => _fetchResourcesPage(pageKey, 'study_material', _studyMaterialPagingController));

      // Handle initial selection
      if (widget.initialItemType != null && widget.initialItemId != null) {
        final key = "${widget.initialItemType}_${widget.initialItemId}";
        _selectedItems.add(key);
        
        // Set initial tab
        if (widget.initialItemType == 'test') {
          _tabController!.index = 0;
        } else if (widget.initialItemType == 'resource' && widget.initialResourceCategory != null) {
          switch (widget.initialResourceCategory) {
            case 'ebook': _tabController!.index = 1; break;
            case 'pyq': _tabController!.index = 2; break;
            case 'current_affair': _tabController!.index = 3; break;
            case 'study_material': _tabController!.index = 4; break;
          }
        }
      }
      _loadUserData();
    } else if (_isItemMode) {
      if (widget.isAuditMode) {
        _tabController = TabController(length: 3, vsync: this);
        _auditPaidPagingController.addPageRequestListener((pageKey) => _fetchAuditPage(pageKey, 'paid', _auditPaidPagingController));
        _auditClaimedPagingController.addPageRequestListener((pageKey) => _fetchAuditPage(pageKey, 'claimed', _auditClaimedPagingController));
        _auditManualPagingController.addPageRequestListener((pageKey) => _fetchAuditPage(pageKey, 'manual_granted', _auditManualPagingController));
      } else {
        _pagingController.addPageRequestListener((pageKey) {
          _fetchUserPage(pageKey);
        });
      }
      _loadItemData();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    _pagingController.dispose();
    _testsPagingController.dispose();
    _ebooksPagingController.dispose();
    _pyqsPagingController.dispose();
    _gkPagingController.dispose();
    _studyMaterialPagingController.dispose();
    _auditPaidPagingController.dispose();
    _auditClaimedPagingController.dispose();
    _auditManualPagingController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      _existingAccess = await AdminService.getUserAccessItemIds(widget.userId!);
      // Refresh controllers to load initial pages with knowledge of existing access
      _testsPagingController.refresh();
      _ebooksPagingController.refresh();
      _pyqsPagingController.refresh();
      _gkPagingController.refresh();
      _studyMaterialPagingController.refresh();
    } catch (e) {
      if (mounted) ErrorUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTestsPage(int pageKey) async {
    try {
      final newItems = await AdminService.getPaginatedMockTests(
        offset: pageKey,
        limit: _pageSize,
        searchQuery: _searchQuery,
      );

      // Filter out items already granted
      final filteredItems = newItems.where((t) => !(_existingAccess['test']?.contains(t['test_id']) ?? false)).toList();

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _testsPagingController.appendLastPage(filteredItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _testsPagingController.appendPage(filteredItems, nextPageKey);
      }
    } catch (error) {
      _testsPagingController.error = error;
    }
  }

  Future<void> _fetchResourcesPage(int pageKey, String type, PagingController<int, Map<String, dynamic>> controller) async {
    try {
      final newItems = await AdminService.getPaginatedResources(
        offset: pageKey,
        limit: _pageSize,
        searchQuery: _searchQuery,
        type: type,
      );

      // Filter out items already granted
      final filteredItems = newItems.where((r) => !(_existingAccess['resource']?.contains(r['id']) ?? false)).toList();

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        controller.appendLastPage(filteredItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        controller.appendPage(filteredItems, nextPageKey);
      }
    } catch (error) {
      controller.error = error;
    }
  }

  Future<void> _loadItemData() async {
    setState(() => _isLoading = true);
    try {
      final existingAccess = await AdminService.getUsersWithAccessToItem(widget.itemType!, widget.itemId!);
      _existingUserAccess = existingAccess;
    } catch (e) {
      if (mounted) ErrorUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserPage(int pageKey) async {
    try {
      final newItems = await AdminService.getPaginatedUsers(
        offset: pageKey,
        limit: _pageSize,
        searchQuery: _searchQuery,
      );

      // Filter out users who already have access
      final filteredItems = newItems.where((u) => !_existingUserAccess.contains(u['id'])).toList();

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(filteredItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(filteredItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Future<void> _fetchAuditPage(int pageKey, String accessType, PagingController<int, Map<String, dynamic>> controller) async {
    try {
      final newItems = await AdminService.getPaginatedUsersByAccessType(
        itemType: widget.itemType!,
        itemId: widget.itemId!,
        accessType: accessType,
        offset: pageKey,
        limit: _pageSize,
        searchQuery: _searchQuery,
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        controller.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        controller.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      controller.error = error;
    }
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    EasyDebounce.debounce('grant-access-search', const Duration(milliseconds: 500), () {
      if (_isItemMode) {
        if (widget.isAuditMode) {
          _auditPaidPagingController.refresh();
          _auditClaimedPagingController.refresh();
          _auditManualPagingController.refresh();
        } else {
          _pagingController.refresh();
        }
      } else {
        _testsPagingController.refresh();
        _ebooksPagingController.refresh();
        _pyqsPagingController.refresh();
        _gkPagingController.refresh();
        _studyMaterialPagingController.refresh();
      }
    });
  }

  void _toggleSelection(String key) {
    setState(() {
      if (_isUserMode) {
        if (_selectedItems.contains(key)) {
          _selectedItems.remove(key);
        } else {
          _selectedItems.add(key);
        }
      } else {
        if (_selectedUserIds.contains(key)) {
          _selectedUserIds.remove(key);
        } else {
          _selectedUserIds.add(key);
        }
      }
    });
  }

  Future<void> _grantAccess() async {
    if ((_isUserMode && _selectedItems.isEmpty) || (_isItemMode && _selectedUserIds.isEmpty)) return;

    setState(() => _isLoading = true);
    try {
      if (_isUserMode) {
        final List<Map<String, dynamic>> toGrant = [];
        for (final key in _selectedItems) {
          final parts = key.split('_');
          final type = parts[0];
          final id = int.parse(parts[1]);

          Map<String, dynamic>? itemData;
          if (type == 'test') {
            // Since it's paginated, we might not have the data in memory if it was from a previous page
            // But for batch granting, we need the snapshot. 
            // We can either fetch it or try to find it in the current controllers' item list.
            itemData = _testsPagingController.itemList?.firstWhere((t) => t['test_id'] == id, orElse: () => {});
          } else {
            final controllers = [_ebooksPagingController, _pyqsPagingController, _gkPagingController, _studyMaterialPagingController];
            for (final controller in controllers) {
              final found = controller.itemList?.firstWhere((r) => r['id'] == id, orElse: () => {});
              if (found != null && found.isNotEmpty) {
                itemData = found;
                break;
              }
            }
          }

          if (itemData == null || itemData.isEmpty) {
            // Fallback: If not found in memory (scrolled away), we'll need to fetch it or just use ID
            // For now, assume it's in memory or fetch it if needed. 
            // Given the batch size, it's safer to fetch the latest snapshot if missing.
            // But usually, the items being granted were just seen by the user.
          }

          toGrant.add({
            'id': id,
            'type': type,
            'snapshot': itemData,
          });
        }

        final success = await AdminService.grantBatchAccess(
          userId: widget.userId!,
          items: toGrant,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully granted access to ${toGrant.length} items')),
          );
          Navigator.pop(context);
        }
      } else if (_isItemMode) {
        final success = await AdminService.grantItemToUsersBatch(
          userIds: _selectedUserIds.toList(),
          item: {
            'id': widget.itemId!,
            'type': widget.itemType!,
            'snapshot': widget.itemSnapshot!,
          },
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully granted access to ${_selectedUserIds.length} users')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) ErrorUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeAccess(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: const Text('Are you sure you want to revoke this user\'s access?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await AdminService.revokeAccess(
        userId: userId,
        itemType: widget.itemType!,
        itemId: widget.itemId!,
      );

      if (success) {
        // Refresh all audit controllers to be safe
        _auditPaidPagingController.refresh();
        _auditClaimedPagingController.refresh();
        _auditManualPagingController.refresh();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access revoked successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) ErrorUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCount = _isUserMode ? _selectedItems.length : _selectedUserIds.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.surface,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: theme.textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: _isUserMode ? 'Search tests or resources...' : 'Search users...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : Text(widget.isAuditMode
                ? 'Access Audit: ${widget.itemTitle}'
                : (_isUserMode
                    ? 'Grant Access: ${widget.username}'
                    : 'Gift: ${widget.itemTitle}')),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                  if (_isItemMode) {
                    if (widget.isAuditMode) {
                      _auditPaidPagingController.refresh();
                      _auditClaimedPagingController.refresh();
                      _auditManualPagingController.refresh();
                    } else {
                      _pagingController.refresh();
                    }
                  }
                }
              });
            },
          ),
          if (selectedCount > 0 && !_isSearching && !widget.isAuditMode)
            TextButton.icon(
              onPressed: _grantAccess,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text('Grant ($selectedCount)'),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            ),
        ],
        bottom: widget.isAuditMode
            ? TabBar(
                controller: _tabController,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(text: 'Paid'),
                  Tab(text: 'Claimed'),
                  Tab(text: 'Manual Access'),
                ],
              )
            : (_isUserMode
                ? TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    indicatorColor: colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Mock Tests'),
                      Tab(text: 'eBooks'),
                      Tab(text: 'PYQs'),
                      Tab(text: 'GK'),
                      Tab(text: 'Study Material'),
                    ],
                  )
                : null),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (_isUserMode 
            ? TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(_testsPagingController, 'test', 'No mock tests available'),
                  _buildCategoryList(_ebooksPagingController, 'ebook', 'No eBooks available'),
                  _buildCategoryList(_pyqsPagingController, 'pyq', 'No PYQs available'),
                  _buildCategoryList(_gkPagingController, 'current_affair', 'No GK resources available'),
                  _buildCategoryList(_studyMaterialPagingController, 'study_material', 'No study materials available'),
                ],
              )
            : (widget.isAuditMode 
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAuditUserList(_auditPaidPagingController, 'No users have paid access', showRevoke: true),
                      _buildAuditUserList(_auditClaimedPagingController, 'No users have claimed access', showRevoke: true),
                      _buildAuditUserList(_auditManualPagingController, 'No users have manual access', showRevoke: true),
                    ],
                  )
                : _buildPaginatedUserList())),
    );
  }

  Widget _buildAuditUserList(PagingController<int, Map<String, dynamic>> controller, String emptyMsg, {bool showRevoke = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return PagedListView<int, Map<String, dynamic>>.separated(
      pagingController: controller,
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      separatorBuilder: (_, __) => Divider(height: 1, indent: 70, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
        itemBuilder: (context, item, index) {
          final name = item['username'] ?? item['email'] ?? 'Unknown User';
          final email = item['email'] ?? '';
          final grantedAt = item['granted_at'] != null
              ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(item['granted_at']).toLocal())
              : '';

          return ListTile(
            tileColor: colorScheme.surface,
            leading: CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '$email\nGranted: $grantedAt',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            isThreeLine: true,
            trailing: showRevoke
                ? IconButton(
                    icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
                    onPressed: () => _revokeAccess(item['id']),
                  )
                : null,
          );
        },
        noItemsFoundIndicatorBuilder: (_) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? 'No matches found' : emptyMsg,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(PagingController<int, Map<String, dynamic>> controller, String typePrefix, String emptyMsg) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return PagedListView<int, Map<String, dynamic>>.separated(
      pagingController: controller,
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.sm + MediaQuery.of(context).padding.bottom,
      ),
      separatorBuilder: (_, __) => Divider(height: 1, indent: 70, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
        itemBuilder: (context, item, index) {
          final id = typePrefix == 'test' ? item['test_id'] : item['id'];
          final key = "${typePrefix}_$id";
          final isSelected = _selectedItems.contains(key);

          return CheckboxListTile(
            tileColor: colorScheme.surface,
            value: isSelected,
            onChanged: (_) => _toggleSelection(key),
            title: Text(
              item['title'] ?? 'Untitled',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              item['description'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                typePrefix == 'test' ? Icons.quiz_outlined : Icons.menu_book_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            activeColor: colorScheme.primary,
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          );
        },
        noItemsFoundIndicatorBuilder: (_) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? 'No matches found' : emptyMsg,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginatedUserList() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Column(
      children: [
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Users for Gifting',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final loadedItems = _pagingController.itemList ?? [];
                    setState(() {
                      if (_selectedUserIds.length == loadedItems.length && loadedItems.isNotEmpty) {
                        _selectedUserIds.clear();
                      } else {
                        _selectedUserIds.addAll(loadedItems.map((u) => u['id'].toString()));
                      }
                    });
                  },
                  child: Text(
                    _selectedUserIds.length == (_pagingController.itemList?.length ?? 0) &&
                            (_pagingController.itemList?.isNotEmpty ?? false)
                        ? 'Deselect Loaded'
                        : 'Select All Loaded',
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: PagedListView<int, Map<String, dynamic>>.separated(
            pagingController: _pagingController,
            padding: EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.sm + MediaQuery.of(context).padding.bottom,
            ),
            separatorBuilder: (_, __) => Divider(height: 1, indent: 70, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
              itemBuilder: (context, user, index) {
                final id = user['id'].toString();
                final isSelected = _selectedUserIds.contains(id);
                final name = user['username'] ?? user['email'] ?? 'Unknown User';
                final phone = user['phone'] ?? user['email'] ?? '';

                return CheckboxListTile(
                  tileColor: colorScheme.surface,
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(id),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.trailing,
                  activeColor: colorScheme.primary,
                  checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                );
              },
              noItemsFoundIndicatorBuilder: (_) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No users found for "$_searchQuery"'
                          : 'No users available for gifting',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
