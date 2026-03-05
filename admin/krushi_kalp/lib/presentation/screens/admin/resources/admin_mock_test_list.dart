import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/services/test_service.dart';
import '../../../../domain/models/mock_test.dart';
import '../../mock_test_upload_screen.dart';
import '../mock_test_edit_screen.dart';

class AdminMockTestList extends StatefulWidget {
  final bool? isFree; // null = all, true = free only, false = paid only

  const AdminMockTestList({super.key, this.isFree});

  @override
  State<AdminMockTestList> createState() => _AdminMockTestListState();
}

class _AdminMockTestListState extends State<AdminMockTestList> {
  // State
  List<MockTest> _allTests = [];
  List<MockTest> _displayTests = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;

  // Filters
  String _searchQuery = '';
  String _sortOption = 'newest'; // newest, oldest, price_asc, price_desc

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() => _isLoading = true);
    _subscription = TestService.streamMockTests().listen((tests) {
      if (mounted) {
        setState(() {
          _allTests = tests;
          _isLoading = false;
          _applyFilters();
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    });
  }

  void _applyFilters() {
    List<MockTest> temp = List.from(_allTests);

    // 0. Filter by isFree (if set)
    if (widget.isFree != null) {
      if (widget.isFree == true) {
        temp = temp.where((t) => t.price == 0).toList();
      } else {
        temp = temp.where((t) => t.price > 0).toList();
      }
    }

    // 1. Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      temp = temp
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.category.toLowerCase().contains(q))
          .toList();
    }

    // 2. Sort
    switch (_sortOption) {
      case 'oldest':
        temp.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_asc':
        temp.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        temp.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
      default:
        temp.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() {
      _displayTests = temp;
    });
  }

  Future<void> _deleteTest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delete Test?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('This action cannot be undone.',
                  style: TextStyle(fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red,
                        elevation: 0),
                    child: const Text('Delete'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await TestService.deleteMockTest(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MockTestUploadScreen()),
          );
        },
        label: const Text('Add Test', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search & Sort Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tests...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Sort by:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _buildSortChip('Newest', 'newest'),
                      _buildSortChip('Oldest', 'oldest'),
                      _buildSortChip('Price: Low to High', 'price_asc'),
                      _buildSortChip('Price: High to Low', 'price_desc'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayTests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('No tests found.',
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: _displayTests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final test = _displayTests[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MockTestEditScreen(test: test),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.4),
                                    width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Leading Icon/Image
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: test.signedUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              child: Image.network(
                                                test.signedUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Icon(
                                                      Icons.broken_image,
                                                      color: Theme.of(context)
                                                          .primaryColor
                                                          .withOpacity(0.5));
                                                },
                                              ),
                                            )
                                          : Icon(Icons.description,
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.7),
                                              size: 30),
                                    ),
                                    const SizedBox(width: 16),
                                    // Title & Subtitle
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            test.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${test.totalQuestions} Qs • ₹${test.price} • ${test.category}',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline_rounded,
                                          color: Colors.red[400]),
                                      onPressed: () => _deleteTest(test.id),
                                    ),
                                    const Icon(Icons.chevron_right_rounded,
                                        color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortOption == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _sortOption = value;
              _applyFilters();
            });
          }
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
