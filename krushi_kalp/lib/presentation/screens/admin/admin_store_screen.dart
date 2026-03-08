import 'package:flutter/material.dart';
import 'resources/admin_mock_test_list.dart';

class AdminStoreScreen extends StatelessWidget {
  const AdminStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manage Store'),
      ),
      body: const AdminMockTestList(),
    );
  }
}
