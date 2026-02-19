import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/banner_service.dart';
import '../../domain/models/home_banner.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/navigation_provider.dart';
import 'login_screen.dart'; // Needed for Logout navigation
import 'my_resources_screen.dart';
import '../providers/resource_provider.dart';
import '../providers/auth_provider.dart';
import 'free_content_screen.dart'; // NEW
import 'package:cached_network_image/cached_network_image.dart'; // NEW
import 'cart_screen.dart';
import 'score_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/common/category_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Aspirant';
  int _currentBannerIndex = 0; // NEW
  List<HomeBanner> _banners = [];
  bool _isLoadingBanners = true;

  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBanners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TestProvider>().fetchTests();
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<ResourceProvider>().fetchPurchasedResources(user.id);
      }
    });
  }

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
                _loadBanners(),
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
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildBannerCarousel(),
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
            leading:
                const Icon(Icons.book_outlined, color: AppColors.neutral900),
            title: const Text('My Tests'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              context
                  .read<NavigationProvider>()
                  .setIndex(1); // Navigate to My Tests
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined,
                color: AppColors.neutral900),
            title: const Text('Downloads'), // Renamed from My Materials
            onTap: () {
              Navigator.pop(context);
              context
                  .read<NavigationProvider>()
                  .setIndex(3); // Navigate to Downloads
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
    if (_isLoadingBanners) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_banners.isEmpty) {
      // Fallback Static Banner if no banners from API
      // Safer to rely on local asset or simple container if network fails
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school,
                size: 48, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text(
              "Welcome to Krushi Kalp",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Using PageView for simplicity as per original code structure, but making it safe
    return Column(
      children: [
        SizedBox(
            height: 160,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              itemCount: _banners.length,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return GestureDetector(
                  onTap: () {
                    // Handle action
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      color: AppColors.neutral100, // Placeholder color
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: CachedNetworkImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          color: AppColors.neutral100,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint(
                              'Failed to load banner image: $url, Error: $error');
                          return Container(
                            color: AppColors.neutral200,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image,
                                    color: AppColors.neutral400),
                                Text('Image Error',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.neutral500)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            )),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppColors.primary)
                    .withOpacity(_currentBannerIndex == entry.key ? 0.9 : 0.4),
              ),
            );
          }).toList(),
        ),
      ],
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
        ],
      ),
    );
  }
}
