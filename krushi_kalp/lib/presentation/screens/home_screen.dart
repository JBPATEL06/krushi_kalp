import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/banner_service.dart';
import '../../domain/models/home_banner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/navigation_provider.dart';
import '../../data/services/app_config_service.dart';
import 'login_screen.dart';
import 'my_resources_screen.dart';
import '../providers/resource_provider.dart';
import '../providers/auth_provider.dart';
import 'free_content_screen.dart';
import 'cart_screen.dart';
import 'score_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/common/category_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/common/responsive_wrapper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Aspirant';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // _loadBanners(); // REMOVED
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TestProvider>().fetchTests();
      // fetchPurchasedResources is already called by MainScreen
    });
  }

  /*
  Future<void> _loadBanners() async {
    if (!mounted) return;
    setState(() => _isLoadingBanners = true);
    try {
      final banners = await BannerService.fetchActiveBanners();
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoadingBanners = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading banners in UI: $e");
      if (mounted) {
        setState(() => _isLoadingBanners = false);
      }
    }
  }
  */

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await Supabase.instance.client
            .from('users')
            .select('username')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null && mounted) {
          setState(() {
            _userName = profile['username'] ?? 'Aspirant';
            _userEmail = user.email ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading home data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.neutral900,
              size: 26,
            ),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "Krushi Kalp",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
        ),
        actions: const [
          SizedBox(
              width:
                  48), // Balancing the leading menu button for true centering
        ],
      ),
      drawer: _buildDrawer(),
      body: Consumer<TestProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _loadUserData(),
                AppConfigService.fetchConfigs(),
                provider.fetchTests(forceRefresh: true),
                context.read<ResourceProvider>().fetchPurchasedResources(
                    context.read<AuthProvider>().currentUser?.id ?? ''),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      'Hello, $_userName',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral900,
                              ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.2), // Animate Greeting
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildBannerCarousel()
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 200.ms)
                      .scale(begin: const Offset(0.95, 0.95)), // Animate Banner
                  const SizedBox(height: AppSpacing.lg),
                  _buildCategoryGrid(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            accountName: Text(
              _userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(_userEmail),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close drawer
                context.read<NavigationProvider>().setIndex(4); // Goto Profile
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
                  style:
                      const TextStyle(fontSize: 32, color: AppColors.primary),
                ),
              ),
            ),
            onDetailsPressed: () {
              Navigator.pop(context); // Close drawer
              context.read<NavigationProvider>().setIndex(4); // Goto Profile
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.home_outlined, color: AppColors.neutral900),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined,
                color: AppColors.neutral900),
            title: const Text('My Cart'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined,
                color: AppColors.neutral900),
            title: const Text('Test Results'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScoreScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded,
                color: AppColors.neutral900),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context
                  .read<NavigationProvider>()
                  .setIndex(4); // Navigate to Profile
            },
          ),
          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.share_outlined, color: AppColors.neutral900),
            title: const Text('Share App'),
            onTap: () {
              Navigator.pop(context);
              Share.share(
                  'Check out Krushi Kalp app for exam preparation: https://play.google.com/store/apps/details?id=com.krushikalp.app');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title:
                const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return StreamBuilder<List<HomeBanner>>(
      stream: BannerService.streamAllBanners(),
      builder: (context, snapshot) {
        // Loading → show shimmer placeholder (NOT static banner)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBannerShimmer();
        }

        final banners = snapshot.data ?? [];
        final activeBanners = banners.where((b) => b.isActive).toList();

        // Only show static banner when there are literally 0 active banners
        if (activeBanners.isEmpty) {
          return _buildStaticBanner();
        }

        // Hand off to isolated StatefulWidget so rebuilds don't reset the slider
        return _BannerAutoSlider(
          banners: activeBanners,
          autoScroll: AppConfigService.bannerAutoScroll,
          interval: AppConfigService.bannerInterval,
        );
      },
    );
  }

  // Shimmer-style loading placeholder shown ONLY while waiting for stream
  Widget _buildBannerShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1200.ms, color: AppColors.neutral100);
  }

  Widget _buildStaticBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      height: context.h(180),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: _buildStaticBannerImage(),
      ),
    );
  }

  Widget _buildStaticBannerImage() {
    return Image.asset(
      'assets/images/homeBanner.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.primary.withOpacity(0.1),
          child: const Center(
            child: Icon(Icons.broken_image, color: AppColors.neutral400),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate aspect ratio dynamically: (Width - margins - spacing) / (Number of columns * required height)
    // We want a minimum height that fits the now-responsive CategoryCard content.
    final horizontalPadding = AppSpacing.lg * 2;
    final gridSpacing = AppSpacing.md;
    final cardWidth = (screenWidth - horizontalPadding - gridSpacing) / 2;

    // Ideal height for CategoryCard with scaled tokens is roughly 100-110 at 375w.
    // We'll use a ratio that ensures a minimum height.
    final cardHeight = context.h(105);
    final dynamicAspectRatio = cardWidth / cardHeight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: dynamicAspectRatio > 1.8
            ? 1.8
            : dynamicAspectRatio < 1.2
                ? 1.2
                : dynamicAspectRatio,
        children: [
          CategoryCard(
            title: 'Daily Current Affair',
            icon: Icons.newspaper,
            color: Colors.deepOrange,
            onTap: () {
              final provider = context.read<ResourceProvider>();
              final hasCurrentAffairs = provider.currentAffairs
                  .any((r) => provider.purchasedResourceIds.contains(r.id));

              if (hasCurrentAffairs) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyResourcesScreen(
                      title: 'My Current Affairs',
                      category: 'Current Affairs',
                    ),
                  ),
                );
              } else {
                context
                    .read<NavigationProvider>()
                    .setStoreCategory('Current Affairs');
                context.read<NavigationProvider>().setIndex(2); // Store
              }
            },
          ),
          CategoryCard(
            title: 'Test Series',
            icon: Icons.quiz_outlined,
            color: Colors.blue,
            onTap: () {
              final hasPurchased =
                  context.read<TestProvider>().purchasedTests.isNotEmpty;
              if (hasPurchased) {
                context.read<NavigationProvider>().setIndex(1); // My Tests
              } else {
                context
                    .read<NavigationProvider>()
                    .setStoreCategory('Mock Tests');
                context.read<NavigationProvider>().setIndex(2); // Store
              }
            },
          ),
          CategoryCard(
            title: 'E-Books',
            icon: Icons.menu_book_rounded,
            color: Colors.green,
            onTap: () {
              final provider = context.read<ResourceProvider>();
              final hasPurchased = provider.ebooks
                  .any((r) => provider.purchasedResourceIds.contains(r.id));

              if (hasPurchased) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyResourcesScreen(
                      title: 'My E-Books',
                      category: 'E-Books',
                    ),
                  ),
                );
              } else {
                context.read<NavigationProvider>().setStoreCategory('E-Books');
                context.read<NavigationProvider>().setIndex(2); // Store
              }
            },
          ),
          CategoryCard(
            title: 'Study Material',
            icon: Icons.description_rounded,
            color: Colors.purple,
            onTap: () {
              final provider = context.read<ResourceProvider>();
              final hasPurchased = provider.studyMaterials
                  .any((r) => provider.purchasedResourceIds.contains(r.id));

              if (hasPurchased) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyResourcesScreen(
                      title: 'My Study Materials',
                      category: 'Study Materials',
                    ),
                  ),
                );
              } else {
                context
                    .read<NavigationProvider>()
                    .setStoreCategory('Study Materials');
                context.read<NavigationProvider>().setIndex(2); // Store
              }
            },
          ),
          CategoryCard(
            title: 'Free Material',
            icon: Icons.card_giftcard,
            color: Colors.amber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FreeContentScreen(),
                ),
              );
            },
          ),
          CategoryCard(
            title: 'PYQs',
            icon: Icons.history_edu_rounded,
            color: Colors.red,
            onTap: () {
              final provider = context.read<ResourceProvider>();
              final hasPurchased = provider.pyqs
                  .any((r) => provider.purchasedResourceIds.contains(r.id));

              if (hasPurchased) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyResourcesScreen(
                      title: 'My PYQs',
                      category: 'PYQs',
                    ),
                  ),
                );
              } else {
                context.read<NavigationProvider>().setStoreCategory('PYQs');
                context.read<NavigationProvider>().setIndex(2); // Store
              }
            },
          ),
        ]
            .animate(interval: 100.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.2, end: 0), // Staggered Animation
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Isolated banner slider — owns PageController + Timer
// so StreamBuilder rebuilds never reset position.
// ─────────────────────────────────────────────────────────────────
class _BannerAutoSlider extends StatefulWidget {
  final List<HomeBanner> banners;
  final bool autoScroll;
  final int interval;

  const _BannerAutoSlider({
    required this.banners,
    required this.autoScroll,
    required this.interval,
  });

  @override
  State<_BannerAutoSlider> createState() => _BannerAutoSliderState();
}

class _BannerAutoSliderState extends State<_BannerAutoSlider> {
  late final PageController _controller;
  int _current = 0;
  List<HomeBanner> _banners = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _banners = widget.banners;
    _controller = PageController(viewportFraction: 0.92);
    _setupAutoPlay();
  }

  @override
  void didUpdateWidget(_BannerAutoSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If banners change, update list
    if (widget.banners != oldWidget.banners) {
      _banners = widget.banners;
    }

    // If configuration changes, reset autoplay
    if (widget.autoScroll != oldWidget.autoScroll ||
        widget.interval != oldWidget.interval) {
      _setupAutoPlay();
    }
  }

  void _setupAutoPlay() {
    _timer?.cancel();
    if (_banners.length > 1 && widget.autoScroll) {
      _timer = Timer.periodic(Duration(seconds: widget.interval), (timer) {
        if (!mounted) return;
        final next = (_current + 1) % _banners.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: context.h(180),
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: AppColors.neutral100,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.neutral200,
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: AppColors.neutral400, size: 40),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dot indicators
        if (_banners.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _banners.asMap().entries.map((entry) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _current == entry.key ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _current == entry.key
                      ? AppColors.primary
                      : AppColors.neutral300,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
