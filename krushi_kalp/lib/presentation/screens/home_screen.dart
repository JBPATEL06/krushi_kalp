import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/test_notifier.dart';
import '../../data/services/banner_service.dart';
import '../../domain/models/home_banner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart'; // FIXED: Added import for radius tokens
import '../providers/navigation_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/app_config_service.dart';
import 'login_screen.dart';
import 'my_resources_screen.dart';
import '../providers/resource_notifier.dart';
import '../providers/auth_notifier.dart';
import '../../utils/responsive.dart';
import 'free_content_screen.dart';
import 'cart_screen.dart';
import 'score_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/common/category_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/common/responsive_wrapper.dart';
import '../../data/services/performance_service.dart';
import '../../domain/models/user_performance.dart';
import '../widgets/performance_card.dart';
import '../../utils/crashlytics_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  void initState() {
    super.initState();
    // _loadBanners(); // REMOVED
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(testNotifierProvider.notifier).fetchTests();
      // fetchPurchasedResources is already called by MainScreen
    });
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1, // FIXED: standard border width
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: theme.colorScheme.onSurface,
              size: context.sp(26), // FIXED: context.sp(26)
            ),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "Krushi Kalp",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          SizedBox(
              width: context.w(
                  48)), // FIXED: context.w(48) - Balancing the leading menu button
        ],
      ),
      drawer: _buildDrawer(),
      body: Consumer(
        builder: (context, ref, child) {
          final testState = ref.watch(testNotifierProvider);
          final authState = ref.watch(authNotifierProvider);
          return RefreshIndicator(
            onRefresh: () async {
              try {
                final authState = ref.read(authNotifierProvider);
                await Future.wait([
                  ref.read(authNotifierProvider.notifier).refreshProfile(),
                  AppConfigService.fetchConfigs(),
                  ref.read(testNotifierProvider.notifier).fetchTests(forceRefresh: true),
                  ref.read(resourceNotifierProvider.notifier).fetchPurchasedResources(
                      authState.user?.id ?? ''),
                ]).timeout(const Duration(seconds: 20));
              } catch (e, stack) {
                CrashlyticsService.instance.recordError(e, stack, reason: 'home_screen');
                // The indicator will stop automatically when this async block finishes
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.h(AppSpacing.xl)),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      'Hello, ${ref.watch(authNotifierProvider).username ?? 'Aspirant'}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.2), // Animate Greeting
                  ),
                  SizedBox(height: context.h(AppSpacing.lg)),
                  _buildBannerCarousel()
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 200.ms)
                      .scale(begin: const Offset(0.95, 0.95)), // Animate Banner
                  SizedBox(height: context.h(AppSpacing.xl)),
                  _buildCategoryGrid(),
                  SizedBox(height: context.h(AppSpacing.xxl)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            accountName: Text(
              authState.username ?? 'Aspirant',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.sp(18)), // FIXED: context.sp(18)
            ),
            accountEmail: Text(authState.user?.email ?? ''),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close drawer
                ref.read(navigationProvider.notifier).setIndex(4); // Goto Profile
              },
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.surface,
                child: Text(
                  (authState.username ?? 'A').isNotEmpty ? (authState.username ?? 'A')[0].toUpperCase() : 'A',
                  style: TextStyle(
                      fontSize: context.sp(32),
                      color:
                          theme.colorScheme.primary), // FIXED: context.sp(32)
                ),
              ),
            ),
            onDetailsPressed: () {
              Navigator.pop(context); // Close drawer
              ref.read(navigationProvider.notifier).setIndex(4); // Goto Profile
            },
          ),
          ListTile(
            leading:
                Icon(Icons.home_outlined, color: theme.colorScheme.onSurface),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context); // Close drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart_outlined,
                color: theme.colorScheme.onSurface),
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
            leading: Icon(Icons.emoji_events_outlined,
                color: theme.colorScheme.onSurface),
            title: const Text('Results'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScoreScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person_outline_rounded,
                color: theme.colorScheme.onSurface),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              ref.read(navigationProvider.notifier).setIndex(4); // Navigate to Profile
            },
          ),
          const Divider(),
          ListTile(
            leading:
                Icon(Icons.share_outlined, color: theme.colorScheme.onSurface),
            title: const Text('Share App'),
            onTap: () {
              Navigator.pop(context);
              Share.share(
                  'Check out Krushi Kalp app for exam preparation: https://play.google.com/store/apps/details?id=com.krushikalp.app');
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline_rounded,
                color: theme.colorScheme.onSurface),
            title: const Text('About Krushi Kalp'),
            onTap: () {
              Navigator.pop(context);
              context.push('/about');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('Logout',
                style: TextStyle(color: theme.colorScheme.error)),
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
                      child: Text('Logout',
                          style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await ref.read(authNotifierProvider.notifier).signOut();
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
      stream: BannerService.instance.streamAllBanners(),
      builder: (context, snapshot) {
        final List<Widget> sliderItems = [
          _buildPerformanceCard(),
        ];

        if (snapshot.connectionState == ConnectionState.waiting) {
          sliderItems.add(_buildBannerShimmer());
        } else {
          final banners = snapshot.data ?? [];
          final activeBanners = banners.where((b) => b.isActive).toList();

          if (activeBanners.isEmpty) {
            sliderItems.add(_buildStaticBanner());
          } else {
            for (final banner in activeBanners) {
              sliderItems.add(_buildBannerImageCard(banner));
            }
          }
        }

        // Hand off to isolated StatefulWidget so rebuilds don't reset the slider
        return _BannerAutoSlider(
          items: sliderItems,
          autoScroll: AppConfigService.bannerAutoScroll,
          interval: AppConfigService.bannerInterval,
        );
      },
    );
  }

  Widget _buildPerformanceCard() {
    final userId = ref.watch(authNotifierProvider).user?.id ?? '';
    if (userId.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<UserPerformance>(
      future: PerformanceService.instance.getUserPerformance(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return PerformanceCard(
              data: UserPerformance.empty(), isLoading: true);
        }
        if (!snapshot.hasData || snapshot.hasError) {
          return const SizedBox.shrink();
        }
        return PerformanceCard(data: snapshot.data!);
      },
    );
  }

  Widget _buildBannerImageCard(HomeBanner banner) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs), // FIXED: AppSpacing.xs (4)
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
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
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Center(
              child: Icon(Icons.broken_image,
                  color: theme.colorScheme.outline,
                  size: context.sp(40)), // FIXED: context.sp(40)
            ),
          ),
        ),
      ),
    );
  }

  // Shimmer-style loading placeholder shown ONLY while waiting for stream
  Widget _buildBannerShimmer() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
        duration: 1200.ms, color: theme.colorScheme.surfaceContainerHighest);
  }

  Widget _buildStaticBanner() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      height: context.h(180), // FIXED: context.h(180) - Specified banner size
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
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
    final theme = Theme.of(context);
    return Image.asset(
      'assets/images/homeBanner.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Center(
            child: Icon(Icons.broken_image, color: theme.colorScheme.outline),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    final theme = Theme.of(context);
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
            color: theme.colorScheme.primary,
            onTap: () {
              final resourceState = ref.read(resourceNotifierProvider);
              final hasCurrentAffairs = resourceState.currentAffairs
                  .any((r) => resourceState.purchasedResourceIds.contains(r.id));

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
                ref.read(navigationProvider.notifier)
                    .setStoreCategory('Current Affairs');
                ref.read(navigationProvider.notifier).setIndex(2); // Store
              }
            },
          ),
          CategoryCard(
            title: 'Mocks',
            icon: Icons.quiz_outlined,
            color: theme.colorScheme.secondary,
            onTap: () {
              final testState = ref.read(testNotifierProvider);
              final hasPurchased = testState.purchasedTestIds.isNotEmpty;
              if (hasPurchased) {
                ref.read(navigationProvider.notifier).setIndex(1); // My Tests
              } else {
                ref.read(navigationProvider.notifier).setStoreCategory('Mock Tests');
                ref.read(navigationProvider.notifier).setIndex(2); // Store
              }
            },
          ),
          CategoryCard(
            title: 'E-Books',
            icon: Icons.menu_book_rounded,
            color: theme.colorScheme.tertiary,
            onTap: () {
              final resourceState = ref.read(resourceNotifierProvider);
              final hasPurchased = resourceState.ebooks
                  .any((r) => resourceState.purchasedResourceIds.contains(r.id));

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
                ref.read(navigationProvider.notifier).setStoreCategory('E-Books');
                ref.read(navigationProvider.notifier).setIndex(2); // Store
              }
            },
          ),
          CategoryCard(
            title: 'Study Material',
            icon: Icons.description_rounded,
            color: theme.colorScheme.primary,
            onTap: () {
              final resourceState = ref.read(resourceNotifierProvider);
              final hasPurchased = resourceState.studyMaterials
                  .any((r) => resourceState.purchasedResourceIds.contains(r.id));

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
                ref.read(navigationProvider.notifier)
                    .setStoreCategory('Study Materials');
                ref.read(navigationProvider.notifier).setIndex(2); // Store
              }
            },
          ),
          CategoryCard(
            title: 'Free Material',
            icon: Icons.card_giftcard,
            color: theme.colorScheme.secondary,
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
            color: theme.colorScheme.error,
            onTap: () {
              final resourceState = ref.read(resourceNotifierProvider);
              final hasPurchased = resourceState.pyqs
                  .any((r) => resourceState.purchasedResourceIds.contains(r.id));

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
                ref.read(navigationProvider.notifier).setStoreCategory('PYQs');
                ref.read(navigationProvider.notifier).setIndex(2); // Store
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
  final List<Widget> items;
  final bool autoScroll;
  final int interval;

  const _BannerAutoSlider({
    required this.items,
    required this.autoScroll,
    required this.interval,
  });

  @override
  State<_BannerAutoSlider> createState() => _BannerAutoSliderState();
}

class _BannerAutoSliderState extends State<_BannerAutoSlider> {
  late final PageController _controller;
  int _current = 0;
  List<Widget> _items = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
    _controller = PageController(viewportFraction: 0.92);
    _setupAutoPlay();
  }

  @override
  void didUpdateWidget(_BannerAutoSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If banners change, update list
    if (widget.items != oldWidget.items) {
      _items = widget.items;
    }

    // If configuration changes, reset autoplay
    if (widget.autoScroll != oldWidget.autoScroll ||
        widget.interval != oldWidget.interval) {
      _setupAutoPlay();
    }
  }

  void _setupAutoPlay() {
    _timer?.cancel();
    if (_items.length > 1 && widget.autoScroll) {
      _timer = Timer.periodic(Duration(seconds: widget.interval), (timer) {
        if (!mounted) return;
        final next = (_current + 1) % _items.length;
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
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          height:
              context.h(180), // FIXED: context.h(180) - Specified banner size
          child: PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              return _items[index];
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm), // FIXED: AppSpacing.sm (8)
        // Dot indicators
        if (_items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _items.asMap().entries.map((entry) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _current == entry.key
                    ? AppSpacing.lg
                    : AppSpacing
                        .sm, // FIXED: AppSpacing.lg (20) : AppSpacing.sm (8)
                height: AppSpacing.sm, // FIXED: AppSpacing.sm (8)
                margin: const EdgeInsets.symmetric(
                    horizontal: 3), // small margin for dots
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                      AppRadius.sm), // FIXED: AppRadius.sm (4)
                  color: _current == entry.key
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
