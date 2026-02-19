import 'package:flutter/material.dart';
import 'resources/admin_mock_test_list.dart'; // Import the new component

class AdminStoreScreen extends StatelessWidget {
  const AdminStoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Store',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading:
            null, // Removed explicit leading/close button for Tab integration
      ),
      body: const AdminMockTestList(), // Default: Show all tests
    );
  }
}
