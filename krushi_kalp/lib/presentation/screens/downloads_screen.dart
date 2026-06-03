import 'package:flutter/material.dart';
import '../../domain/models/resource.dart';
import '../../domain/models/mock_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/resource_notifier.dart';
import '../providers/test_notifier.dart';
import '../providers/auth_notifier.dart';
import '../../data/services/download_service.dart';
import '../../data/services/resource_service.dart';
import '../../data/services/mock_test_file_service.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/common/responsive_wrapper.dart';
import '../widgets/common/modern_card.dart';
import 'mock_test_files_screen.dart';
import 'resource_files_screen.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with WidgetsBindingObserver {
  // We need to track download status for items to sort/display correctly
  Map<String, bool> _localStatus = {};
  bool _isLoading = true;

  // Storage & Filter State
  int _totalBytesUsed = 0;
  String _searchQuery = '';
  String _activeFilter = 'All Files';

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

    try {
      final user = ref.read(authProvider).user;

      // -- Guard: ensure purchased resources are loaded
      final resourceState = ref.read(resourceProvider);
      if (resourceState.purchasedResources.isEmpty && user != null) {
        await ref
            .read(resourceProvider.notifier)
            .fetchPurchasedResources(user.id);
      }

      // -- Guard: ensure purchased mock tests are loaded
      final testState = ref.read(testProvider);
      if (testState.userTests.isEmpty && user != null) {
        await ref.read(testProvider.notifier).fetchUserTests(user.id);
      }

      // Re-read state after potential fetches above
      final myResources = ref.read(resourceProvider).purchasedResources;
      final myTests = ref.read(testProvider).userTests;

      final downloadService = DownloadService();
      final userId = user?.id;

      // -- Resource download checks --
      // A resource is "downloaded" if ANY of its supplementary files exist locally.
      // Legacy fallback: also check the old single-file format resource_<id>.pdf.
      final resourceChecks = myResources.map((r) async {
        try {
          final files = await ResourceService.instance.fetchResourceFiles(r.id);
          if (files.isNotEmpty) {
            for (final file in files) {
              final filename = 'resource_file_${file.id}.pdf';
              final exists = await downloadService.isFileDownloaded(filename, userId: userId);
              if (exists) return MapEntry<String, bool>('res_${r.id}', true);
            }
            return MapEntry<String, bool>('res_${r.id}', false);
          } else {
            final legacyFilename = 'resource_${r.id}.pdf';
            final exists = await downloadService.isFileDownloaded(legacyFilename, userId: userId);
            return MapEntry<String, bool>('res_${r.id}', exists);
          }
        } catch (_) {
          final legacyFilename = 'resource_${r.id}.pdf';
          final exists = await downloadService.isFileDownloaded(legacyFilename, userId: userId);
          return MapEntry<String, bool>('res_${r.id}', exists);
        }
      }).toList();

      // -- Mock test download checks --
      // A test is "downloaded" if ANY of its supplementary files exist locally.
      // Legacy fallback: also check the old single JSON format mock_test_<id>.json.
      final testChecks = myTests.map((t) async {
        try {
          final files = await MockTestFileService.instance.fetchMockTestFiles(t.id);
          if (files.isNotEmpty) {
            for (final file in files) {
              final pdfFilename = 'mock_test_file_${file.id}.pdf';
              final jsonFilename = 'mock_test_quiz_${file.id}.json';
              final pdfExists = await downloadService.isFileDownloaded(pdfFilename, userId: userId);
              final jsonExists = await downloadService.isFileDownloaded(jsonFilename, userId: userId);
              if (pdfExists || jsonExists) return MapEntry<String, bool>('test_${t.id}', true);
            }
            return MapEntry<String, bool>('test_${t.id}', false);
          } else {
            final legacyFilename = 'mock_test_${t.id}.json';
            final exists = await downloadService.isFileDownloaded(legacyFilename, userId: userId);
            return MapEntry<String, bool>('test_${t.id}', exists);
          }
        } catch (_) {
          final legacyFilename = 'mock_test_${t.id}.json';
          final exists = await downloadService.isFileDownloaded(legacyFilename, userId: userId);
          return MapEntry<String, bool>('test_${t.id}', exists);
        }
      }).toList();

      // -- Run all checks in parallel --
      final results = await Future.wait<MapEntry<String, bool>>(
        [...resourceChecks, ...testChecks],
      );
      final newStatus = Map<String, bool>.fromEntries(results);

      // -- Storage calculation --
      int usedBytes = 0;
      if (userId != null) {
        usedBytes = await downloadService.getTotalStorageUsed(userId);
      }

      if (mounted) {
        setState(() {
          _localStatus = newStatus;
          _totalBytesUsed = usedBytes;
        });
      }
    } catch (e) {
      debugPrint('DownloadsScreen: Error checking downloads: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    final user = ref.read(authProvider).user;
    if (user == null) return;

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
        if (id.startsWith('res_')) {
          final resId = int.tryParse(id.replaceFirst('res_', ''));
          if (resId != null) {
            await ds.deleteFile('resource_$resId.pdf', userId: user.id);
            try {
              final files = await ResourceService.instance.fetchResourceFiles(resId);
              for (final file in files) {
                await ds.deleteFile('resource_file_${file.id}.pdf', userId: user.id);
              }
            } catch (_) {}
          }
        } else if (id.startsWith('test_')) {
          final testId = int.tryParse(id.replaceFirst('test_', ''));
          if (testId != null) {
            await ds.deleteFile('mock_test_$testId.json', userId: user.id);
            try {
              final files = await MockTestFileService.instance.fetchMockTestFiles(testId);
              for (final file in files) {
                await ds.deleteFile('mock_test_file_${file.id}.pdf', userId: user.id);
                await ds.deleteFile('mock_test_quiz_${file.id}.json', userId: user.id);
              }
            } catch (_) {}
          }
        }
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
    final user = ref.read(authProvider).user;
    if (user == null) return;

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
      await DownloadService().clearAllDownloads(user.id);
      await _checkDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All downloads cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filters = [
      'All Files',
      'Mocks',
      'PYQs',
      'E-Books',
      'Daily CA',
      'Study Material'
    ];
    // Watch state for changes
    final resourceState = ref.watch(resourceProvider);
    final testState = ref.watch(testProvider);

    final myTests = testState.userTests;
    final myResources = resourceState.purchasedResources;

    final theme = Theme.of(context);
    final displayItems = <dynamic>[];

    for (var r in myResources) {
      if (_localStatus['res_${r.id}'] == true) {
        final matchesSearch =
            r.title.toLowerCase().contains(_searchQuery.toLowerCase());

        // Detailed Filtering Logic
        bool matchesFilter = _activeFilter == 'All Files';
        if (!matchesFilter) {
          if (_activeFilter == 'E-Books' && r.type == ResourceType.eBook) {
            matchesFilter = true;
          }
          if (_activeFilter == 'Daily CA' &&
              r.type == ResourceType.currentAffair) {
            matchesFilter = true;
          }
          if (_activeFilter == 'PYQs' && r.type == ResourceType.pyq) {
            matchesFilter = true;
          }
          if (_activeFilter == 'Study Material' &&
              r.type == ResourceType.studyMaterial) {
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
        final matchesFilter = _activeFilter == 'All Files' ||
            _activeFilter == 'Mocks' ||
            (_activeFilter == 'PYQs' &&
                (t.category.toUpperCase().contains('PYQ') ||
                    t.title.toUpperCase().contains('PYQ')));
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

                    // Modern Search Bar
                    ModernCard(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      child: Container(
                        height: context.h(50),
                        alignment: Alignment.center,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            fontSize: context.sp(15),
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search your downloads...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                              fontSize: context.sp(14),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.primary,
                              size: context.sp(22),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: context.w(AppSpacing.md)),
                          ),
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
                        children: filters.map((filter) {
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResourceFilesScreen(resource: resource),
              ),
            );
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
                    "${(resource.category != null && resource.category!.trim().isNotEmpty) ? resource.category! : 'PDF'} • PDF",
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ResourceFilesScreen(resource: resource),
                    ),
                  );
                },
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MockTestFilesScreen(test: test),
              ),
            );
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
                    "${test.totalQuestions} Tests",
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MockTestFilesScreen(test: test),
                    ),
                  );
                },
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
