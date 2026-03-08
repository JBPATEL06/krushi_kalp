import 'package:flutter/material.dart';
import 'tabs/feature_control_tab.dart';
import 'tabs/banner_management_tab.dart';
import 'tabs/content_management_tab.dart';

class ManageAppScreen extends StatelessWidget {
  const ManageAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Features", icon: Icon(Icons.toggle_on_rounded)),
              Tab(text: "Banners", icon: Icon(Icons.image_rounded)),
              Tab(text: "Content", icon: Icon(Icons.description_rounded)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FeatureControlTab(),
            BannerManagementTab(),
            ContentManagementTab(),
          ],
        ),
      ),
    );
  }
}
