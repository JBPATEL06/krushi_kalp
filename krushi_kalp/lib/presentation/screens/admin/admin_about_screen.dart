import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/services/app_config_service.dart';
import '../../../../utils/responsive.dart';

class AdminAboutScreen extends StatefulWidget {
  const AdminAboutScreen({super.key});

  @override
  State<AdminAboutScreen> createState() => _AdminAboutScreenState();
}

class _AdminAboutScreenState extends State<AdminAboutScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _appNameCtrl = TextEditingController();
  final TextEditingController _versionCtrl = TextEditingController();
  final TextEditingController _taglineCtrl = TextEditingController();
  final TextEditingController _supportLabelCtrl = TextEditingController();
  final TextEditingController _supportDescCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _telegramCtrl = TextEditingController();
  // REMOVED: _footerTextCtrl

  List<Map<String, dynamic>> _features = [];
  List<Map<String, dynamic>> _sections = [];

  static const List<String> _availableIcons = [
    'quiz', 'menu_book', 'bar_chart', 'science', 'agriculture',
    'school', 'emoji_events', 'chat', 'download', 'star'
  ];

  static const List<String> _availableSectionIcons = [
    'auto_awesome', 'mission', 'vision', 'history', 'group', 
    'agriculture', 'school', 'star'
  ];

  static IconData iconFromString(String name) {
    const map = {
      'quiz': Icons.quiz,
      'menu_book': Icons.menu_book,
      'bar_chart': Icons.bar_chart,
      'science': Icons.science,
      'agriculture': Icons.agriculture,
      'school': Icons.school,
      'emoji_events': Icons.emoji_events,
      'chat': Icons.chat,
      'download': Icons.download,
      'star': Icons.star,
    };
    return map[name] ?? Icons.help_outline;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await AppConfigService.fetchAboutConfig();
      if (!mounted) return;
      setState(() {
        _appNameCtrl.text = data['app_name'] ?? '';
        _versionCtrl.text = data['version'] ?? '';
        _taglineCtrl.text = data['tagline'] ?? '';
        
        final support = data['support'] as Map<String, dynamic>? ?? {};
        _supportLabelCtrl.text = support['support_label'] ?? '';
        _supportDescCtrl.text = support['support_description'] ?? '';
        _emailCtrl.text = support['email'] ?? '';
        _telegramCtrl.text = support['telegram'] ?? '';

        _features = List<Map<String, dynamic>>.from(data['features'] ?? []);
        _sections = List<Map<String, dynamic>>.from(data['sections'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    final updatedData = {
      'app_name': _appNameCtrl.text.trim(),
      'version': _versionCtrl.text.trim(),
      'tagline': _taglineCtrl.text.trim(),
      'features': _features,
      'sections': _sections,
      'support': {
        'support_label': _supportLabelCtrl.text.trim(),
        'support_description': _supportDescCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'telegram': _telegramCtrl.text.trim(),
      },
    };

    try {
      await AppConfigService.updateAboutConfig(updatedData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('About page updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addFeature() {
    setState(() {
      _features.add({
        'icon': 'star',
        'title': '',
        'subtitle': ''
      });
    });
  }

  void _addSection() {
    setState(() {
      _sections.add({
        'icon': 'auto_awesome',
        'title': '',
        'description': ''
      });
    });
  }

  void _removeSection(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section?'),
        content: const Text('Are you sure you want to remove this content section?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _sections.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _removeFeature(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feature?'),
        content: const Text('Are you sure you want to remove this feature from the list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _features.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _versionCtrl.dispose();
    _taglineCtrl.dispose();
    _supportLabelCtrl.dispose();
    _supportDescCtrl.dispose();
    _emailCtrl.dispose();
    _telegramCtrl.dispose();
    // REMOVED: _footerTextCtrl.dispose()
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl + MediaQuery.of(context).padding.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AdminHeroPreview(
                appName: _appNameCtrl.text,
                version: _versionCtrl.text,
                tagline: _taglineCtrl.text,
              ),
              SizedBox(height: AppSpacing.md),
              ExpansionTile(
                title: const Text("Edit Branding", style: TextStyle(fontWeight: FontWeight.bold)),
                collapsedBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                childrenPadding: EdgeInsets.all(AppSpacing.md),
                children: [
                  TextFormField(
                    controller: _appNameCtrl,
                    decoration: const InputDecoration(labelText: 'App Name', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onChanged: (_) => setState((){}),
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _versionCtrl,
                    decoration: const InputDecoration(labelText: 'Version', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onChanged: (_) => setState((){}),
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _taglineCtrl,
                    decoration: const InputDecoration(labelText: 'Tagline', border: OutlineInputBorder()),
                    onChanged: (_) => setState((){}),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              ExpansionTile(
                title: const Text("Dynamic Sections (Mission, etc.)", style: TextStyle(fontWeight: FontWeight.bold)),
                collapsedBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                childrenPadding: EdgeInsets.all(AppSpacing.md),
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final s = _sections[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: AppSpacing.md),
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  DropdownButton<String>(
                                    value: _availableSectionIcons.contains(s['icon']) ? s['icon'] : 'auto_awesome',
                                    items: _availableSectionIcons.map((icon) => DropdownMenuItem(
                                      value: icon,
                                      child: Icon(icon == 'auto_awesome' ? Icons.auto_awesome : 
                                                 icon == 'mission' ? Icons.flag :
                                                 icon == 'vision' ? Icons.visibility :
                                                 icon == 'history' ? Icons.history :
                                                 icon == 'group' ? Icons.group :
                                                 icon == 'agriculture' ? Icons.agriculture :
                                                 icon == 'school' ? Icons.school :
                                                 icon == 'star' ? Icons.star : Icons.auto_awesome),
                                    )).toList(),
                                    onChanged: (val) => setState(() => s['icon'] = val),
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: s['title'],
                                      decoration: const InputDecoration(labelText: 'Section Title'),
                                      onChanged: (val) => s['title'] = val,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removeSection(index),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSpacing.md),
                              TextFormField(
                                initialValue: s['description'],
                                maxLines: 3,
                                decoration: const InputDecoration(labelText: 'Description'),
                                onChanged: (val) => s['description'] = val,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ElevatedButton.icon(
                    onPressed: _addSection,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Section'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              ExpansionTile(
                title: const Text("Key Features", style: TextStyle(fontWeight: FontWeight.bold)),
                collapsedBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                childrenPadding: EdgeInsets.all(AppSpacing.md),
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _features.length,
                    itemBuilder: (context, index) {
                      final f = _features[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: AppSpacing.md),
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  DropdownButton<String>(
                                    value: _availableIcons.contains(f['icon']) ? f['icon'] : 'star',
                                    items: _availableIcons.map((i) => DropdownMenuItem(
                                      value: i,
                                      child: Icon(iconFromString(i)),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _features[index]['icon'] = val);
                                    },
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeFeature(index),
                                  )
                                ],
                              ),
                              TextFormField(
                                initialValue: f['title'],
                                decoration: const InputDecoration(labelText: 'Title'),
                                onChanged: (val) => _features[index]['title'] = val,
                              ),
                              TextFormField(
                                initialValue: f['subtitle'],
                                decoration: const InputDecoration(labelText: 'Subtitle'),
                                onChanged: (val) => _features[index]['subtitle'] = val,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: _addFeature,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Feature'),
                  )
                ],
              ),
              SizedBox(height: AppSpacing.md),
              ExpansionTile(
                title: const Text("Support Info", style: TextStyle(fontWeight: FontWeight.bold)),
                collapsedBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                childrenPadding: EdgeInsets.all(AppSpacing.md),
                children: [
                  TextFormField(
                    controller: _supportLabelCtrl,
                    decoration: const InputDecoration(labelText: 'Support Card Headline', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _supportDescCtrl,
                    decoration: const InputDecoration(labelText: 'Support Description', border: OutlineInputBorder()),
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Support Email', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _telegramCtrl,
                    decoration: const InputDecoration(labelText: 'Telegram Link/Username', border: OutlineInputBorder()),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              // REMOVED: Footer Text ExpansionTile
              SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHeroPreview extends StatelessWidget {
  final String appName;
  final String version;
  final String tagline;

  const _AdminHeroPreview({
    required this.appName,
    required this.version,
    required this.tagline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.agriculture_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            appName.isEmpty ? 'Krushi Kalp' : appName,
            style: AppTypography.heading.copyWith(
              color: theme.colorScheme.primary,
              fontSize: context.sp(20),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Version $version',
            style: AppTypography.bodyLabel.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLabel.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
