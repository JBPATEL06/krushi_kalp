import 'package:flutter/material.dart';
import 'tabs/feature_control_tab.dart';
import 'tabs/banner_management_tab.dart';
import 'tabs/content_management_tab.dart';

class ManageAppScreen extends StatelessWidget {
  const ManageAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Manage App"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.black,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "Features", icon: Icon(Icons.toggle_on)),
              Tab(text: "Banners", icon: Icon(Icons.image)),
              Tab(text: "Content", icon: Icon(Icons.description)),
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
