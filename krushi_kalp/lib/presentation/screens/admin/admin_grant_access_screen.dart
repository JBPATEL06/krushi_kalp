import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/services/admin_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../utils/error_utils.dart';

class AdminGrantAccessScreen extends ConsumerStatefulWidget {
  final String userId;
  final String username;
  final String? initialItemType;
  final int? initialItemId;
  final String? initialResourceCategory;

  const AdminGrantAccessScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialItemType,
    this.initialItemId,
    this.initialResourceCategory,
  });

  @override
  ConsumerState<AdminGrantAccessScreen> createState() => _AdminGrantAccessScreenState();
}

class _AdminGrantAccessScreenState extends ConsumerState<AdminGrantAccessScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Data lists
  List<Map<String, dynamic>> _allTests = [];
  List<Map<String, dynamic>> _allResources = [];
  Map<String, Set<int>> _existingAccess = {};

  // Selection states
  final Set<String> _selectedItems = {}; // Format: "type_id" e.g., "test_123" or "resource_456"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Handle initial selection
    if (widget.initialItemType != null && widget.initialItemId != null) {
      final key = "${widget.initialItemType}_${widget.initialItemId}";
      _selectedItems.add(key);
      
      // Set initial tab
      if (widget.initialItemType == 'test') {
        _tabController.index = 0;
      } else if (widget.initialItemType == 'resource' && widget.initialResourceCategory != null) {
        switch (widget.initialResourceCategory) {
          case 'ebook': _tabController.index = 1; break;
          case 'pyq': _tabController.index = 2; break;
          case 'current_affair': _tabController.index = 3; break;
          case 'study_material': _tabController.index = 4; break;
        }
      }
    }
    
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        AdminService.fetchAllMockTests(),
        AdminService.fetchAllResources(),
        AdminService.getUserAccessItemIds(widget.userId),
      ]);

      _allTests = results[0] as List<Map<String, dynamic>>;
      _allResources = results[1] as List<Map<String, dynamic>>;
      _existingAccess = results[2] as Map<String, Set<int>>;

      debugPrint('ADMIN_GRANT: Fetched ${_allTests.length} tests');
      for (var t in _allTests) {
        debugPrint('TEST ID: ${t['test_id']} TITLE: ${t['title']}');
      }
      
      debugPrint('ADMIN_GRANT: Fetched ${_allResources.length} resources');
      final resourceTypes = _allResources.map((r) => r['type']).toSet();
      debugPrint('RESOURCE TYPES IN DB: $resourceTypes');

    } catch (e) {
      if (mounted) ErrorUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filtered lists based on existing access and search query
  List<Map<String, dynamic>> get _availableTests {
    final filtered = _allTests
        .where((t) => !(_existingAccess['test']?.contains(t['test_id']) ?? false))
        .toList();
    
    if (_searchQuery.isEmpty) return filtered;
    return filtered.where((t) => 
      (t['title']?.toString().toLowerCase() ?? '').contains(_searchQuery.toLowerCase())
    ).toList();
  }

  List<Map<String, dynamic>> _getAvailableResources(String type) {
    final filtered = _allResources
        .where((r) => r['type'] == type)
        .where((r) => !(_existingAccess['resource']?.contains(r['id']) ?? false))
        .toList();

    if (_searchQuery.isEmpty) return filtered;
    return filtered.where((r) => 
      (r['title']?.toString().toLowerCase() ?? '').contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _toggleSelection(String key) {
    setState(() {
      if (_selectedItems.contains(key)) {
        _selectedItems.remove(key);
      } else {
        _selectedItems.add(key);
      }
    });
  }

  Future<void> _grantAccess() async {
    if (_selectedItems.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> toGrant = [];
      
      for (final key in _selectedItems) {
        final parts = key.split('_');
        final type = parts[0];
        final id = int.parse(parts[1]);

        Map<String, dynamic>? itemData;
        if (type == 'test') {
          itemData = _allTests.firstWhere((t) => t['test_id'] == id);
        } else {
          itemData = _allResources.firstWhere((r) => r['id'] == id);
        }

        toGrant.add({
          'id': id,
          'type': type,
          'snapshot': itemData, // Storing full snapshot as per schema
        });
      }

      final success = await AdminService.grantBatchAccess(
        userId: widget.userId,
        items: toGrant,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully granted access to ${toGrant.length} items')),
        );
        Navigator.pop(context);
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

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search tests or resources...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            )
          : Text('Grant Access: ${widget.username}'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          if (_selectedItems.isNotEmpty && !_isSearching)
            TextButton.icon(
              onPressed: _grantAccess,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text('Grant (${_selectedItems.length})'),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            ),
        ],
        bottom: TabBar(
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
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(_availableTests, 'test', 'No new mock tests available'),
              _buildCategoryList(_getAvailableResources('ebook'), 'resource', 'No new eBooks available'),
              _buildCategoryList(_getAvailableResources('pyq'), 'resource', 'No new PYQs available'),
              _buildCategoryList(_getAvailableResources('current_affair'), 'resource', 'No new GK available'),
              _buildCategoryList(_getAvailableResources('study_material'), 'resource', 'No new study materials available'),
            ],
          ),
    );
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> items, String typePrefix, String emptyMsg) {
    final filteredItems = _searchQuery.isEmpty 
        ? items 
        : items.where((item) {
            final title = (item['title'] ?? '').toString().toLowerCase();
            return title.contains(_searchQuery.toLowerCase());
          }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_searchQuery.isNotEmpty ? 'No matches found' : emptyMsg, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: filteredItems.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
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
          ),
        ),
      ],
    );
  }
}
