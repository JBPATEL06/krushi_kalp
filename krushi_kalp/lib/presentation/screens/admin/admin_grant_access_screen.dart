import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      _pagingController.addPageRequestListener((pageKey) {
        _fetchUserPage(pageKey);
      });
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

  void _onSearchChanged(String query) {
    _searchQuery = query;
    EasyDebounce.debounce('grant-access-search', const Duration(milliseconds: 500), () {
      if (_isItemMode) {
        _pagingController.refresh();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCount = _isUserMode ? _selectedItems.length : _selectedUserIds.length;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
              decoration: InputDecoration(
                hintText: _isUserMode ? 'Search tests or resources...' : 'Search users...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withValues(alpha: 0.7)),
                border: InputBorder.none,
              ),
              onChanged: _onSearchChanged,
            )
          : Text(_isUserMode ? 'Grant Access: ${widget.username}' : 'Gift: ${widget.itemTitle}'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                  if (_isItemMode) _pagingController.refresh();
                }
              });
            },
          ),
          if (selectedCount > 0 && !_isSearching)
            TextButton.icon(
              onPressed: _grantAccess,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text('Grant ($selectedCount)'),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            ),
        ],
        bottom: _isUserMode 
          ? TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Mock Tests'),
                Tab(text: 'eBooks'),
                Tab(text: 'PYQs'),
                Tab(text: 'GK'),
                Tab(text: 'Study Material'),
              ],
            )
          : null,
      ),
      body: _isUserMode 
        ? (_isLoading 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(_testsPagingController, 'test', 'No new mock tests available'),
                  _buildCategoryList(_ebooksPagingController, 'resource', 'No new eBooks available'),
                  _buildCategoryList(_pyqsPagingController, 'resource', 'No new PYQs available'),
                  _buildCategoryList(_gkPagingController, 'resource', 'No new GK available'),
                  _buildCategoryList(_studyMaterialPagingController, 'resource', 'No new study materials available'),
                ],
              ))
        : _buildPaginatedUserList(),
    );
  }

  Widget _buildCategoryList(PagingController<int, Map<String, dynamic>> controller, String typePrefix, String emptyMsg) {
    return PagedListView<int, Map<String, dynamic>>.separated(
      pagingController: controller,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
      builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
        itemBuilder: (context, item, index) {
          final id = typePrefix == 'test' ? item['test_id'] : item['id'];
          final key = "${typePrefix}_$id";
          final isSelected = _selectedItems.contains(key);
          
          return CheckboxListTile(
            value: isSelected,
            onChanged: (_) => _toggleSelection(key),
            title: Text(item['title'] ?? 'Untitled', 
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(item['description'] ?? '', 
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            secondary: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                typePrefix == 'test' ? Icons.quiz_outlined : Icons.menu_book_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            activeColor: Theme.of(context).colorScheme.primary,
            checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          );
        },
        noItemsFoundIndicatorBuilder: (_) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_searchQuery.isNotEmpty ? 'No matches found' : emptyMsg, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginatedUserList() {
    return Column(
      children: [
        if (!_isLoading)
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Select Users for Gifting', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
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
                  child: Text(_selectedUserIds.length == (_pagingController.itemList?.length ?? 0) && (_pagingController.itemList?.isNotEmpty ?? false)
                    ? 'Deselect Loaded' 
                    : 'Select All Loaded'),
                )
              ],
            ),
          ),
        Expanded(
          child: PagedListView<int, Map<String, dynamic>>.separated(
            pagingController: _pagingController,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
            builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
              itemBuilder: (context, user, index) {
                final id = user['id'].toString();
                final isSelected = _selectedUserIds.contains(id);
                final name = user['username'] ?? user['email'] ?? 'Unknown User';
                final phone = user['phone'] ?? user['email'] ?? '';
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(id),
                  title: Text(name, 
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(phone, 
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  secondary: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', 
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  controlAffinity: ListTileControlAffinity.trailing,
                  activeColor: Theme.of(context).colorScheme.primary,
                  checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                );
              },
              noItemsFoundIndicatorBuilder: (_) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(_searchQuery.isNotEmpty ? 'No users found for "$_searchQuery"' : 'No users available for gifting', style: const TextStyle(color: Colors.grey)),
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
