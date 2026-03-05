import 'package:flutter/material.dart';
import '../../../../domain/models/offer.dart';
import '../../../../data/services/offer_service.dart';
import '../../widgets/common/network_error_state.dart';
import 'admin_offer_manage_screen.dart';

class AdminOfferListScreen extends StatefulWidget {
  final bool showOnlyActive;
  const AdminOfferListScreen({super.key, this.showOnlyActive = false});

  @override
  State<AdminOfferListScreen> createState() => _AdminOfferListScreenState();
}

class _AdminOfferListScreenState extends State<AdminOfferListScreen> {
  // Stream Management
  Stream<List<Offer>>? _offersStream;
  int _streamId = 0; // To force rebuild

  // Selection
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  bool _showActiveOnly = false; // Local filter
  bool _sortByNewest = false; // Sort filter
  String _filterType = 'ALL'; // 'ALL', 'COUPON', 'SALE'
  String _searchQuery = ''; // Search query
  final TextEditingController _searchController = TextEditingController();

  // Loading State
  int? _updatingOfferId; // ID of offer currently being toggled

  @override
  void initState() {
    super.initState();
    _showActiveOnly = widget.showOnlyActive;
    _refreshOffers();
  }

  void _refreshOffers() {
    setState(() {
      _streamId++;
      _offersStream = OfferService.streamOffers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Offer?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await OfferService.deleteOffer(id);
        if (mounted) {
          if (result == 'ARCHIVED') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Offer is in use. It has been DEACTIVATED (Archived) instead.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
            // Refresh to show updated status
            _refreshOffers();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Offer deleted successfully.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _toggleStatus(Offer offer, bool newStatus) async {
    setState(() {
      _updatingOfferId = offer.id;
    });

    try {
      // Construct updated offer
      final updatedOffer = offer.copyWith(isActive: newStatus);

      await OfferService.updateOffer(updatedOffer);

      // Force refresh since Realtime might be disabled
      _refreshOffers();
    } finally {
      if (mounted) {
        setState(() {
          _updatingOfferId = null;
        });
      }
    }
  }

  Future<void> _bulkDeactivate(List<Offer> allOffers) async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deactivate ${_selectedIds.length} Offers?'),
        content: const Text('These offers will be marked as inactive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate All',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (var id in _selectedIds) {
        // Find offer in current list
        try {
          final offer = allOffers.firstWhere((o) => o.id == id);
          if (offer.isActive) {
            await _toggleStatus(offer, false);
          }
        } catch (_) {}
      }
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  List<Offer> _filterOffers(List<Offer> offers) {
    var filtered = List<Offer>.from(offers);

    // 1. Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((o) =>
              (o.code?.toLowerCase().contains(q) ?? false) ||
              (o.title.toLowerCase().contains(q)))
          .toList();
    }

    // 2. Filter Active
    if (_showActiveOnly) {
      filtered = filtered.where((o) => o.isActive).toList();
    }

    // 3. Filter Type (Coupon vs Sale)
    if (_filterType == 'COUPON') {
      filtered = filtered.where((o) => !o.isSale).toList();
    } else if (_filterType == 'SALE') {
      filtered = filtered.where((o) => o.isSale).toList();
    }

    // 4. Sort
    if (_sortByNewest) {
      filtered.sort((a, b) => b.id.compareTo(a.id));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedIds.length} Selected')
            : const Text('Manage Offers',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                      _selectedIds.clear();
                      _isSelectionMode = false;
                    }))
            : null,
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _refreshOffers,
            )
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.blue[800],
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Offer',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminOfferManageScreen()));
              },
            ),
      body: StreamBuilder<List<Offer>>(
          key: ValueKey(_streamId), // Force rebuild on refresh
          stream: _offersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return NetworkErrorState(
                message: isNetworkError(snapshot.error)
                    ? 'Unable to load offers. Check your connection.'
                    : 'Error: ${snapshot.error}',
                onRetry: _refreshOffers,
              );
            }

            final allOffers = snapshot.data ?? [];
            final displayedOffers = _filterOffers(allOffers);

            return Column(
              children: [
                if (_isSelectionMode && _selectedIds.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: Colors.orange[50],
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${_selectedIds.length} selected"),
                        TextButton.icon(
                          icon: const Icon(Icons.block, color: Colors.orange),
                          label: const Text("Deactivate Selected",
                              style: TextStyle(color: Colors.orange)),
                          onPressed: () => _bulkDeactivate(allOffers),
                        )
                      ],
                    ),
                  ),

                // Filter Toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search offers...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text("Filter:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            FilterChip(
                              label: const Text('All'),
                              selected: !_showActiveOnly,
                              onSelected: (v) {
                                setState(() {
                                  _showActiveOnly = false;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Active Only'),
                              selected: _showActiveOnly,
                              onSelected: (v) {
                                setState(() {
                                  _showActiveOnly = true;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Newest'),
                              selected: _sortByNewest,
                              onSelected: (v) {
                                setState(() {
                                  _sortByNewest = v;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text("Type:",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            FilterChip(
                              label: const Text('All'),
                              selected: _filterType == 'ALL',
                              onSelected: (v) =>
                                  setState(() => _filterType = 'ALL'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Coupons'),
                              selected: _filterType == 'COUPON',
                              onSelected: (v) =>
                                  setState(() => _filterType = 'COUPON'),
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: const Text('Sales'),
                              selected: _filterType == 'SALE',
                              onSelected: (v) =>
                                  setState(() => _filterType = 'SALE'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: displayedOffers.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedOffers.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final offer = displayedOffers[index];
                            final isExpired = !offer.isActive;
                            final isSelected = _selectedIds.contains(offer.id);

                            return InkWell(
                              onLongPress: () {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedIds.add(offer.id);
                                });
                              },
                              onTap: () {
                                if (_isSelectionMode) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedIds.remove(offer.id);
                                    } else {
                                      _selectedIds.add(offer.id);
                                    }
                                    if (_selectedIds.isEmpty) {
                                      _isSelectionMode = false;
                                    }
                                  });
                                } else {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              AdminOfferManageScreen(
                                                  offer: offer)));
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue[50]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : (isExpired
                                            ? Colors.grey.withOpacity(0.2)
                                            : Colors.blue.withOpacity(0.6)),
                                    width: isSelected ? 2 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.08),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      if (_isSelectionMode)
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                right: 12),
                                            child: Icon(
                                                isSelected
                                                    ? Icons.check_box
                                                    : Icons
                                                        .check_box_outline_blank,
                                                color: Colors.blue))
                                      else
                                        // Icon Badge
                                        Container(
                                          width: 50,
                                          height: 50,
                                          margin:
                                              const EdgeInsets.only(right: 16),
                                          decoration: BoxDecoration(
                                            color: isExpired
                                                ? Colors.grey[100]
                                                : Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Icon(
                                            isExpired
                                                ? Icons.access_time
                                                : Icons.local_offer_rounded,
                                            color: isExpired
                                                ? Colors.grey
                                                : Colors.blue[600],
                                            size: 24,
                                          ),
                                        ),

                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              offer.code ??
                                                  'Store Sale', // Handle Null
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isExpired
                                                    ? Colors.grey[400]
                                                    : (offer.code == null
                                                        ? Colors.green[700]
                                                        : const Color(
                                                            0xFF1E293B)),
                                                decoration: isExpired
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              offer.title,
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 13,
                                                height: 1.4,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Actions
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (_updatingOfferId == offer.id)
                                            const SizedBox(
                                              width: 30,
                                              height: 30,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          else
                                            Switch(
                                                value: offer.isActive,
                                                onChanged: (v) =>
                                                    _toggleStatus(offer, v)),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.redAccent,
                                                size: 20),
                                            onPressed: () => _delete(offer.id),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No offers created yet.',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
