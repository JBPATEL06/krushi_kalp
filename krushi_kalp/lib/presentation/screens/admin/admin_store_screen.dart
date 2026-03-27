import 'package:flutter/material.dart';
import 'resources/admin_mock_test_list.dart';

class AdminStoreScreen extends StatelessWidget {
  const AdminStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Store'),
      ),
      body: const AdminMockTestList(),
    );
  }
}
