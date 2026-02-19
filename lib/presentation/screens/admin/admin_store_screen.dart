import 'package:flutter/material.dart';
import 'package:krushi_kalp/core/theme/app_colors.dart';
import 'resources/admin_mock_test_list.dart';

class AdminStoreScreen extends StatelessWidget {
  const AdminStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Manage Store',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: null,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: const AdminMockTestList(),
    );
  }
}
