import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import 'pdf_viewer_screen.dart';
import '../../domain/models/resource.dart';
import '../../domain/models/mock_test.dart';
import 'package:provider/provider.dart';
import '../providers/resource_provider.dart';
import '../providers/test_provider.dart';
import '../../data/services/download_service.dart';
import '../../core/theme/app_spacing.dart';
import '../utils/exam_helper.dart';
import '../widgets/common/responsive_wrapper.dart';
import '../widgets/common/modern_card.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with WidgetsBindingObserver {
  // We need to track download status for items to sort/display correctly
  Map<String, bool> _localStatus = {};
  bool _isLoading = true;

  // Storage & Filter State
  int _totalBytesUsed = 0;
  String _searchQuery = '';
  String _activeFilter = 'All Files';
  final List<String> _filters = ['All Files', 'Mocks', 'Ebook', 'CA', 'GK'];

  final TextEditingController _searchController = TextEditingController();

  // Selection State
  Set<String> _selectedItems = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDownloads();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDownloads();
    }
  }

  Future<void> _checkDownloads() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final resourceProvider = context.read<ResourceProvider>();
    final testProvider = context.read<TestProvider>();

    // If purchased resources haven't been loaded yet, fetch them now
    final userId = AuthService.instance.currentUser?.id;
    if (resourceProvider.purchasedResources.isEmpty && userId != null) {
      await resourceProvider.fetchPurchasedResources(userId);
    }

    final myResources = resourceProvider.purchasedResources;
    final myTests = testProvider.userTests;

    final downloadService = DownloadService();

    // Check ALL purchased resources (regardless of fileUrl)
    final resourceChecks = myResources.map((r) async {
      final filename = 'resource_${r.id}.pdf';
      final exists =
          await downloadService.isFileDownloaded(filename, userId: userId);
      return MapEntry<String, bool>('res_${r.id}', exists);
    }).toList();

    final testChecks =
        myTests.where((t) => t.filePath.isNotEmpty).map((t) async {
      final exists = await downloadService
          .isFileDownloaded('mock_test_${t.id}.json', userId: userId);
      return MapEntry<String, bool>('test_${t.id}', exists);
    }).toList();

    final results = await Future.wait([...resourceChecks, ...testChecks]);
    final newStatus = Map<String, bool>.fromEntries(results);

    // --- Storage Calculation ---
    if (userId != null) {
      final used = await downloadService.getTotalStorageUsed(userId);

      if (mounted) {
        setState(() {
          _localStatus = newStatus;
          _totalBytesUsed = used; // Update storage in setState
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _localStatus = newStatus;
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
        if (_selectedItems.isEmpty) _isSelectionMode = false;
      } else {
        _selectedItems.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _toggleSelectAll(List<dynamic> visibleItems) {
    setState(() {
      if (_selectedItems.length == visibleItems.length) {
        _selectedItems.clear();
        _isSelectionMode = false;
      } else {
        _selectedItems = visibleItems
            .map((item) {
              if (item is Resource) return 'res_${item.id}';
              if (item is MockTest) return 'test_${item.id}';
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toSet();
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${_selectedItems.length} items?'),
        content:
            const Text('Are you sure you want to delete the selected files?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final ds = DownloadService();
      for (final id in _selectedItems) {
        final filename = id.startsWith('res_')
            ? 'resource_${id.replaceFirst('res_', '')}.pdf'
            : 'mock_test_${id.replaceFirst('test_', '')}.json';
        await ds.deleteFile(filename, userId: uid);
      }
      _selectedItems.clear();
      _isSelectionMode = false;
      await _checkDownloads();
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (bytes == 0) ? 0 : (bytes.toString().length - 1) / 3;
    var index = i.floor();
    return "${(bytes / (1 << (index * 10))).toStringAsFixed(1)} ${suffixes[index]}";
  }

  Future<void> _clearStorage() async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Downloads'),
        content: const Text(
            'This will delete ALL downloaded files from your device. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await DownloadService().clearAllDownloads(uid);
      await _checkDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All downloads cleared')),
        );
      }
    }
  }

  /// Opens a resource PDF after verifying ownership and purchase status.
  Future<void> _openResourceSecurely(Resource resource) async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;

    final filename = 'resource_${resource.id}.pdf';
    final ds = DownloadService();

    // 1. Ownership check — manifest must confirm this user downloaded the file
    final owned = await ds.verifyOwnership(filename, userId: uid);
    if (!owned) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Access denied: this file belongs to another account.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. Purchase check — current user must have this resource purchased
    final resourceProvider = context.read<ResourceProvider>();
    if (!resourceProvider.purchasedResourceIds.contains(resource.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Access denied: you have not purchased this resource.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 3. Open file
    final path = await ds.getLocalPath(filename, userId: uid);
    if (await File(path).exists() && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PdfViewerScreen(file: File(path), title: resource.title),
        ),
      );
    }
  }

  /// Starts a mock test after verifying ownership and purchase status.
  Future<void> _startTestSecurely(MockTest test) async {
    final uid = AuthService.instance.currentUser?.id;
    if (uid == null) return;

    final filename = 'mock_test_${test.id}.json';
    final ds = DownloadService();

    // 1. Ownership check
    final owned = await ds.verifyOwnership(filename, userId: uid);
    if (!owned) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Access denied: this file belongs to another account.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. Purchase check — current user must have this test purchased
    final testProvider = context.read<TestProvider>();
    final isPurchased = testProvider.userTests.any((t) => t.id == test.id);
    if (!isPurchased) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied: you have not purchased this test.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 3. Start exam
    if (mounted) {
      await ExamHelper.startExam(context, test);
      _checkDownloads();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch providers for changes
    final resourceProvider = context.watch<ResourceProvider>();
    final testProvider = context.watch<TestProvider>();

    final myTests = testProvider.userTests;
    final myResources = resourceProvider.purchasedResources;

    final displayItems = <dynamic>[];

    for (var r in myResources) {
      if (_localStatus['res_${r.id}'] == true) {
        final matchesSearch =
            r.title.toLowerCase().contains(_searchQuery.toLowerCase());

        // Detailed Filtering Logic
        bool matchesFilter = _activeFilter == 'All Files';
        if (!matchesFilter) {
          if (_activeFilter == 'Ebook' && r.type == ResourceType.eBook) {
            matchesFilter = true;
          }
          if (_activeFilter == 'CA' && r.type == ResourceType.currentAffair) {
            matchesFilter = true;
          }
          if (_activeFilter == 'GK' &&
              (r.type == ResourceType.studyMaterial ||
                  r.type == ResourceType.pyq)) {
            matchesFilter = true;
          }
        }

        if (matchesSearch && matchesFilter) displayItems.add(r);
      }
    }

    for (var t in myTests) {
      if (_localStatus['test_${t.id}'] == true) {
        final matchesSearch =
            t.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesFilter =
            _activeFilter == 'All Files' || _activeFilter == 'Mock Test';
        if (matchesSearch && matchesFilter) displayItems.add(t);
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _isSelectionMode
            ? IconButton(
                icon: Icon(Icons.close_rounded,
                    color: theme.colorScheme.onSurface, size: context.sp(24)),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedItems.clear();
                  });
                },
              )
            : null,
        title: Text(
          _isSelectionMode ? "${_selectedItems.length} Selected" : "Downloads",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: context.sp(20),
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: theme.colorScheme.error, size: context.sp(24)),
              onPressed: _deleteSelected,
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _checkDownloads,
              color: theme.colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    EdgeInsets.symmetric(horizontal: context.w(AppSpacing.lg)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.h(AppSpacing.md)),

                    Container(
                      height: context.h(45),
                      padding: EdgeInsets.symmetric(
                          horizontal: context.w(AppSpacing.sm)),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(fontSize: context.sp(14)),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                              fontSize: context.sp(14)),
                          prefixIcon: Icon(Icons.search_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: context.sp(22)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: context.h(12)),
                        ),
                      ),
                    ),

                    SizedBox(height: context.h(AppSpacing.lg)),

                    // Storage Management Card
                    _buildStorageCard(theme),

                    SizedBox(height: context.h(AppSpacing.xl)),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _activeFilter == filter;
                          return Padding(
                            padding: EdgeInsets.only(
                                right: context.w(AppSpacing.sm)),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (val) =>
                                  setState(() => _activeFilter = filter),
                              showCheckmark: isSelected,
                              checkmarkColor: theme.colorScheme.onPrimary,
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : theme.colorScheme.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(context.w(8)),
                              ),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: context.sp(13),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: context.w(AppSpacing.md)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    SizedBox(height: context.h(AppSpacing.xl)),

                    // List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Downloads",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.sp(16),
                                  ),
                        ),
                        TextButton(
                          onPressed: () => _toggleSelectAll(displayItems),
                          child: Text(
                              _selectedItems.length == displayItems.length
                                  ? "Unselect All"
                                  : "Select All",
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: context.sp(14))),
                        ),
                      ],
                    ),

                    // Downloads List
                    if (displayItems.isEmpty)
                      _buildEmptyState(theme)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayItems.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: context.h(AppSpacing.md)),
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          if (item is Resource) {
                            return _buildResourceCard(theme, item);
                          }
                          if (item is MockTest) {
                            return _buildTestCard(theme, item);
                          }
                          return const SizedBox();
                        },
                      ),

                    SizedBox(
                        height: context.h(AppSpacing.huge) +
                            MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStorageCard(ThemeData theme) {
    return ModernCard(
      padding: EdgeInsets.all(context.w(AppSpacing.lg)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded,
                  color: theme.colorScheme.primary, size: context.sp(20)),
              SizedBox(width: context.w(AppSpacing.sm)),
              Text(
                "${_formatSize(_totalBytesUsed)} used",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(14),
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _clearStorage,
            child: Text(
              "Clean Up",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: context.sp(13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.h(AppSpacing.huge)),
        child: Column(
          children: [
            Icon(Icons.file_download_off_rounded,
                size: context.w(64),
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            SizedBox(height: context.h(AppSpacing.md)),
            Text("No matching downloads found",
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(ThemeData theme, Resource resource) {
    final id = 'res_${resource.id}';
    final isSelected = _selectedItems.contains(id);

    return ModernCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(context.w(AppSpacing.md)),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(id);
          } else {
            _openResourceSecurely(resource);
          }
        },
        onLongPress: () => _toggleSelection(id),
        child: Row(
          children: [
            if (_isSelectionMode) ...[
              Icon(
                isSelected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: context.sp(24),
              ),
              SizedBox(width: context.w(AppSpacing.md)),
            ],
            // Icon Placeholder
            Container(
              width: context.w(45),
              height: context.w(45),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(context.w(AppSpacing.radiusMd)),
              ),
              child: Icon(Icons.picture_as_pdf_rounded,
                  color: theme.colorScheme.error, size: context.sp(20)),
            ),
            SizedBox(width: context.w(AppSpacing.md)),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sp(14),
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    "${resource.category ?? 'PDF'} • PDF",
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: context.sp(11),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isSelectionMode)
              ElevatedButton(
                onPressed: () => _openResourceSecurely(resource),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                      horizontal: context.w(12), vertical: 0),
                  minimumSize: Size(0, context.h(30)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.w(8))),
                ),
                child: Text("Open",
                    style: TextStyle(
                        fontSize: context.sp(12), fontWeight: FontWeight.bold)),
              ),
            if (_isSelectionMode)
              Icon(Icons.drag_indicator_rounded,
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  size: context.sp(20)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(ThemeData theme, MockTest test) {
    final id = 'test_${test.id}';
    final isSelected = _selectedItems.contains(id);

    return ModernCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(context.w(AppSpacing.md)),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(id);
          } else {
            _startTestSecurely(test);
          }
        },
        onLongPress: () => _toggleSelection(id),
        child: Row(
          children: [
            if (_isSelectionMode) ...[
              Icon(
                isSelected
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: context.sp(24),
              ),
              SizedBox(width: context.w(AppSpacing.md)),
            ],
            Container(
              width: context.w(45),
              height: context.w(45),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(context.w(AppSpacing.radiusMd)),
              ),
              child: Icon(Icons.quiz_rounded,
                  color: theme.colorScheme.primary, size: context.sp(20)),
            ),
            SizedBox(width: context.w(AppSpacing.md)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sp(14),
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    "${test.totalQuestions} Questions",
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: context.sp(11),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isSelectionMode)
              ElevatedButton(
                onPressed: () => _startTestSecurely(test),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.tertiary,
                  foregroundColor: theme.colorScheme.onTertiary,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                      horizontal: context.w(12), vertical: 0),
                  minimumSize: Size(0, context.h(30)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(context.w(8))),
                ),
                child: Text("Attempt",
                    style: TextStyle(
                        fontSize: context.sp(12), fontWeight: FontWeight.bold)),
              ),
            if (_isSelectionMode)
              Icon(Icons.drag_indicator_rounded,
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  size: context.sp(20)),
          ],
        ),
      ),
    );
  }
}
