import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/banner_service.dart';
import '../../domain/models/home_banner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radius.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TestProvider>().fetchTests();
    });
  }

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        shape: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: colorScheme.onSurface,
              size: 26,
            ),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "Krushi Kalp",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        actions: const [
          SizedBox(width: 48),
        ],
      ),
      drawer: _buildDrawer(),
      body: Consumer<TestProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            onRefresh: () async {
              await Future.wait([
                _loadUserData(),
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildBannerCarousel()
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 200.ms)
                      .scale(begin: const Offset(0.95, 0.95)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            accountName: Text(
              _userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(_userEmail),
            currentAccountPicture: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.read<NavigationProvider>().setIndex(4);
              },
              child: CircleAvatar(
                backgroundColor: colorScheme.onPrimary,
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            onDetailsPressed: () {
              Navigator.pop(context);
              context.read<NavigationProvider>().setIndex(4);
            },
          ),
          ListTile(
            leading: Icon(Icons.home_outlined, color: colorScheme.onSurface),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart_outlined,
                color: colorScheme.onSurface),
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
            leading:
                Icon(Icons.emoji_events_outlined, color: colorScheme.onSurface),
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
            leading: Icon(Icons.person_outline_rounded,
                color: colorScheme.onSurface),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.read<NavigationProvider>().setIndex(4);
            },
          ),
          Divider(color: colorScheme.outline.withOpacity(0.1)),
          ListTile(
            leading: Icon(Icons.share_outlined, color: colorScheme.onSurface),
            title: const Text('Share App'),
            onTap: () {
              Navigator.pop(context);
              Share.share(
                  'Check out Krushi Kalp app for exam preparation: https://play.google.com/store/apps/details?id=com.krushikalp.app');
            },
          ),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: colorScheme.error),
            title: Text('Logout', style: TextStyle(color: colorScheme.error)),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: colorScheme.surface,
                  surfaceTintColor: colorScheme.surfaceTint,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg)),
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
                          style: TextStyle(color: colorScheme.error)),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBannerShimmer();
        }

        final banners = snapshot.data ?? [];
        final activeBanners = banners.where((b) => b.isActive).toList();

        if (activeBanners.isEmpty) {
          return _buildStaticBanner();
        }

        return _BannerAutoSlider(
          banners: activeBanners,
          autoScroll: AppConfigService.bannerAutoScroll,
          interval: AppConfigService.bannerInterval,
        );
      },
    );
  }

  Widget _buildBannerShimmer() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: colorScheme.surfaceVariant.withOpacity(0.3),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
        duration: 1200.ms, color: colorScheme.surfaceVariant.withOpacity(0.1));
  }

  Widget _buildStaticBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: _buildStaticBannerImage(),
      ),
    );
  }

  Widget _buildStaticBannerImage() {
    final colorScheme = Theme.of(context).colorScheme;
    return Image.asset(
      'assets/images/homeBanner.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colorScheme.primary.withOpacity(0.1),
          child: Center(
            child: Icon(Icons.broken_image_rounded,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5), size: 40),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.5,
        children: [
          CategoryCard(
            title: 'Daily Current Affair',
            icon: Icons.newspaper_rounded,
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
                context.read<NavigationProvider>().setIndex(2);
              }
            },
          ),
          CategoryCard(
            title: 'Test Series',
            icon: Icons.quiz_rounded,
            color: Colors.blue,
            onTap: () {
              final hasPurchased =
                  context.read<TestProvider>().purchasedTests.isNotEmpty;
              if (hasPurchased) {
                context.read<NavigationProvider>().setIndex(1);
              } else {
                context
                    .read<NavigationProvider>()
                    .setStoreCategory('Mock Tests');
                context.read<NavigationProvider>().setIndex(2);
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
                context.read<NavigationProvider>().setIndex(2);
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
                context.read<NavigationProvider>().setIndex(2);
              }
            },
          ),
          CategoryCard(
            title: 'Free Material',
            icon: Icons.card_giftcard_rounded,
            color: Colors.amber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FreeContentScreen()),
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
                context.read<NavigationProvider>().setIndex(2);
              }
            },
          ),
        ]
            .animate(interval: 100.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.2, end: 0),
      ),
    );
  }
}

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
  late final List<HomeBanner> _banners;

  @override
  void initState() {
    super.initState();
    _banners = widget.banners;
    _controller = PageController(viewportFraction: 0.92);
    if (_banners.length > 1 && widget.autoScroll) _startAutoPlay();
  }

  void _startAutoPlay() {
    Future.delayed(Duration(seconds: widget.interval), () {
      if (!mounted) return;
      final next = (_current + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      if (widget.autoScroll) _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      child: Center(
                        child: Icon(Icons.broken_image_rounded,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.5),
                            size: 40),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
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
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.3),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
