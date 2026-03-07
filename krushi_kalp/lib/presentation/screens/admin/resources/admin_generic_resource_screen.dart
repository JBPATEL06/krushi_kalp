import 'package:flutter/material.dart';

class AdminGenericResourceScreen extends StatelessWidget {
  final String title;
  final Widget child;

  const AdminGenericResourceScreen({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: child,
    );
  }
}
