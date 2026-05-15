import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/supabase_service.dart';
import '../services/local_database.dart';
import 'manage_foods_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _supabase = SupabaseService();
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalDatabase.instance.clearAllData();
      await _supabase.signOut();
    }
  }

  void _editTargets() {
    final targetsAsync = ref.read(userTargetsProvider);
    targetsAsync.whenData((targets) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditTargetsScreen(targets: targets),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final targetsAsync = ref.watch(userTargetsProvider);
    final user = _supabase.currentUserEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account section
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Signed in as'),
            subtitle: Text(user ?? 'Unknown'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: _signOut,
          ),

          const Divider(),

          // Targets section
          const _SectionHeader(title: 'Daily Targets'),
          targetsAsync.when(
            loading: () => const ListTile(
              title: Text('Loading...'),
            ),
            error: (e, _) => ListTile(
              title: Text('Error: $e'),
            ),
            data: (targets) => Column(
              children: [
                _TargetTile(
                    label: 'Calories', value: targets.calories, unit: 'kcal'),
                _TargetTile(
                    label: 'Protein', value: targets.protein, unit: 'g'),
                _TargetTile(label: 'Carbs', value: targets.carbs, unit: 'g'),
                _TargetTile(label: 'Fat', value: targets.fat, unit: 'g'),
                _TargetTile(label: 'Fiber', value: targets.fiber, unit: 'g'),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit All Targets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editTargets,
          ),

          const Divider(),

          // Food Database section
          const _SectionHeader(title: 'Food Database'),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Manage Foods'),
            subtitle: const Text('Add, edit, or remove foods'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageFoodsScreen()),
            ),
          ),

          const Divider(),

          // About section
          const _SectionHeader(title: 'About'),
          FutureBuilder<PackageInfo>(
            future: _packageInfoFuture,
            builder: (context, snapshot) {
              final packageInfo = snapshot.data;
              final versionText = packageInfo == null
                  ? 'Loading...'
                  : '${packageInfo.version} (${packageInfo.buildNumber})';

              return ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: Text(versionText),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  final String label;
  final double value;
  final String unit;

  const _TargetTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        '${value.round()} $unit',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class EditTargetsScreen extends ConsumerStatefulWidget {
  final UserTargets targets;

  const EditTargetsScreen({super.key, required this.targets});

  @override
  ConsumerState<EditTargetsScreen> createState() => _EditTargetsScreenState();
}

class _EditTargetsScreenState extends ConsumerState<EditTargetsScreen> {
  late final Map<String, TextEditingController> _controllers;
  bool _isSaving = false;

  final _fields = [
    ('calories', 'Calories', 'kcal'),
    ('protein', 'Protein', 'g'),
    ('carbs', 'Carbohydrates', 'g'),
    ('fat', 'Fat', 'g'),
    ('fiber', 'Fiber', 'g'),
    ('sugar', 'Sugar (max)', 'g'),
    ('saturatedFat', 'Saturated Fat (max)', 'g'),
    ('sodium', 'Sodium (max)', 'mg'),
    ('potassium', 'Potassium', 'mg'),
    ('calcium', 'Calcium', 'mg'),
    ('iron', 'Iron', 'mg'),
    ('magnesium', 'Magnesium', 'mg'),
    ('cholesterol', 'Cholesterol (max)', 'mg'),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = {
      'calories': TextEditingController(
          text: widget.targets.calories.round().toString()),
      'protein': TextEditingController(
          text: widget.targets.protein.round().toString()),
      'carbs':
          TextEditingController(text: widget.targets.carbs.round().toString()),
      'fat': TextEditingController(text: widget.targets.fat.round().toString()),
      'fiber':
          TextEditingController(text: widget.targets.fiber.round().toString()),
      'sugar':
          TextEditingController(text: widget.targets.sugar.round().toString()),
      'saturatedFat': TextEditingController(
          text: widget.targets.saturatedFat.round().toString()),
      'sodium':
          TextEditingController(text: widget.targets.sodium.round().toString()),
      'potassium': TextEditingController(
          text: widget.targets.potassium.round().toString()),
      'calcium': TextEditingController(
          text: widget.targets.calcium.round().toString()),
      'iron':
          TextEditingController(text: widget.targets.iron.round().toString()),
      'magnesium': TextEditingController(
          text: widget.targets.magnesium.round().toString()),
      'cholesterol': TextEditingController(
          text: widget.targets.cholesterol.round().toString()),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final updatedTargets = widget.targets.copyWith(
        calories: double.tryParse(_controllers['calories']!.text) ??
            widget.targets.calories,
        protein: double.tryParse(_controllers['protein']!.text) ??
            widget.targets.protein,
        carbs: double.tryParse(_controllers['carbs']!.text) ??
            widget.targets.carbs,
        fat: double.tryParse(_controllers['fat']!.text) ?? widget.targets.fat,
        fiber: double.tryParse(_controllers['fiber']!.text) ??
            widget.targets.fiber,
        sugar: double.tryParse(_controllers['sugar']!.text) ??
            widget.targets.sugar,
        saturatedFat: double.tryParse(_controllers['saturatedFat']!.text) ??
            widget.targets.saturatedFat,
        sodium: double.tryParse(_controllers['sodium']!.text) ??
            widget.targets.sodium,
        potassium: double.tryParse(_controllers['potassium']!.text) ??
            widget.targets.potassium,
        calcium: double.tryParse(_controllers['calcium']!.text) ??
            widget.targets.calcium,
        iron:
            double.tryParse(_controllers['iron']!.text) ?? widget.targets.iron,
        magnesium: double.tryParse(_controllers['magnesium']!.text) ??
            widget.targets.magnesium,
        cholesterol: double.tryParse(_controllers['cholesterol']!.text) ??
            widget.targets.cholesterol,
      );

      await ref.read(syncServiceProvider).updateUserTargets(updatedTargets);
      ref.invalidate(userTargetsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Targets updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Targets'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _fields.length,
        itemBuilder: (context, index) {
          final (key, label, unit) = _fields[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: _controllers[key],
              decoration: InputDecoration(
                labelText: label,
                suffixText: unit,
              ),
              keyboardType: TextInputType.number,
            ),
          );
        },
      ),
    );
  }
}
