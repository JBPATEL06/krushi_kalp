import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

class ThemeTestScreen extends StatelessWidget {
  const ThemeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Theme Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_4),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Typography',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Display Large', style: theme.textTheme.displayLarge),
                  Text('Headline Large', style: theme.textTheme.headlineLarge),
                  Text('Title Large', style: theme.textTheme.titleLarge),
                  Text('Body Large', style: theme.textTheme.bodyLarge),
                  Text('Label Large', style: theme.textTheme.labelLarge),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              'Buttons',
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  ElevatedButton(
                      onPressed: () {}, child: const Text('Elevated')),
                  FilledButton(onPressed: () {}, child: const Text('Filled')),
                  OutlinedButton(
                      onPressed: () {}, child: const Text('Outlined')),
                  const TextButton(
                      onPressed: null, child: Text('Disabled Text')),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              'Cards',
              Column(
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('Premium Card'),
                      subtitle: const Text(
                          'Testing the tokenized radius and spacing.'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              'Inputs',
              Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_outline),
                      errorText: 'Verification failed',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              'Selection',
              Row(
                children: [
                  Checkbox(value: true, onChanged: (v) {}),
                  const Text('Selected'),
                  SizedBox(width: AppSpacing.lg),
                  Radio(value: true, groupValue: true, onChanged: (v) {}),
                  const Text('Radio'),
                  SizedBox(width: AppSpacing.lg),
                  Switch(value: true, onChanged: (v) {}),
                  const Text('Switch'),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            _buildSection(
              context,
              'Chips',
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  const Chip(label: Text('Flutter')),
                  ChoiceChip(label: const Text('Indigo'), selected: true),
                  const FilterChip(
                      label: Text('Saffron'),
                      selected: false,
                      onSelected: null),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        SizedBox(height: AppSpacing.md),
        content,
      ],
    );
  }
}
