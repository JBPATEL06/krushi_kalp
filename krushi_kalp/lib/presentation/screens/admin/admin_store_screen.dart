import 'package:flutter/material.dart';
import 'resources/admin_mock_test_list.dart';

class AdminStoreScreen extends StatelessWidget {
  const AdminStoreScreen({super.key});

  static final GlobalKey<AdminMockTestListState> _listKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _listKey.currentState?.refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: AdminMockTestList(key: _listKey),
    );
  }
}
