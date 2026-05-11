import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class ManageFoodsScreen extends ConsumerStatefulWidget {
  const ManageFoodsScreen({super.key});

  @override
  ConsumerState<ManageFoodsScreen> createState() => _ManageFoodsScreenState();
}

class _ManageFoodsScreenState extends ConsumerState<ManageFoodsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(foodSearchQueryProvider.notifier).state = query;
  }

  void _openFoodForm([Food? food]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodFormScreen(food: food),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foodsAsync = ref.watch(filteredFoodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Foods'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Foods',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: foodsAsync.when(
              data: (foods) {
                if (foods.isEmpty) {
                  return const Center(
                    child: Text('No foods found'),
                  );
                }
                return ListView.separated(
                  itemCount: foods.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final food = foods[index];
                    return ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.calories.toStringAsFixed(2)} kcal per ${food.unit} '
                        '• default ${food.defaultQty} ${food.unit} '
                        '• step ${food.incrementBy}',
                      ),
                      trailing: food.isDefault
                          ? const Chip(label: Text('Standard'))
                          : const Icon(Icons.chevron_right),
                      onTap: () => _openFoodForm(food),
                      onLongPress:
                          food.isDefault ? null : () => _confirmDelete(food),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openFoodForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(Food food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food'),
        content: Text('Are you sure you want to delete "${food.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && food.id != null) {
      ref.read(foodNotifierProvider.notifier).deleteFood(food.id!);
    }
  }
}

class FoodFormScreen extends ConsumerStatefulWidget {
  final Food? food;

  const FoodFormScreen({super.key, this.food});

  @override
  ConsumerState<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends ConsumerState<FoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  bool get _isStandardFood => widget.food?.isDefault ?? false;

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _unitController;
  late final TextEditingController _defaultQtyController;
  late final TextEditingController _incrementByController;

  // Macro controllers map
  final Map<String, TextEditingController> _macroControllers = {};

  final _macros = [
    ('calories', 'Calories', 'kcal'),
    ('protein', 'Protein', 'g'),
    ('carbs', 'Carbohydrates', 'g'),
    ('fat', 'Fat', 'g'),
    ('fiber', 'Fiber', 'g'),
    ('sugar', 'Sugar', 'g'),
    ('saturatedFat', 'Saturated Fat', 'g'),
    ('sodium', 'Sodium', 'mg'),
    ('potassium', 'Potassium', 'mg'),
    ('calcium', 'Calcium', 'mg'),
    ('iron', 'Iron', 'mg'),
    ('magnesium', 'Magnesium', 'mg'),
    ('cholesterol', 'Cholesterol', 'mg'),
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.food;
    _nameController = TextEditingController(text: f?.name ?? '');
    _unitController = TextEditingController(text: f?.unit ?? 'serving');
    _defaultQtyController =
        TextEditingController(text: f?.defaultQty.toString() ?? '1');
    _incrementByController =
        TextEditingController(text: f?.incrementBy.toString() ?? '1');

    // Initialize macro controllers
    _macroControllers['calories'] =
        TextEditingController(text: f?.calories.toString() ?? '0');
    _macroControllers['protein'] =
        TextEditingController(text: f?.protein.toString() ?? '0');
    _macroControllers['carbs'] =
        TextEditingController(text: f?.carbs.toString() ?? '0');
    _macroControllers['fat'] =
        TextEditingController(text: f?.fat.toString() ?? '0');
    _macroControllers['fiber'] =
        TextEditingController(text: f?.fiber.toString() ?? '0');
    _macroControllers['sugar'] =
        TextEditingController(text: f?.sugar.toString() ?? '0');
    _macroControllers['saturatedFat'] =
        TextEditingController(text: f?.saturatedFat.toString() ?? '0');
    _macroControllers['sodium'] =
        TextEditingController(text: f?.sodium.toString() ?? '0');
    _macroControllers['potassium'] =
        TextEditingController(text: f?.potassium.toString() ?? '0');
    _macroControllers['calcium'] =
        TextEditingController(text: f?.calcium.toString() ?? '0');
    _macroControllers['iron'] =
        TextEditingController(text: f?.iron.toString() ?? '0');
    _macroControllers['magnesium'] =
        TextEditingController(text: f?.magnesium.toString() ?? '0');
    _macroControllers['cholesterol'] =
        TextEditingController(text: f?.cholesterol.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _defaultQtyController.dispose();
    _incrementByController.dispose();
    for (final c in _macroControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_isStandardFood) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final food = Food(
        id: widget.food?.id,
        userId: widget.food?.userId,
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
        defaultQty: double.tryParse(_defaultQtyController.text) ?? 1,
        incrementBy: double.tryParse(_incrementByController.text) ?? 1,
        calories: double.tryParse(_macroControllers['calories']!.text) ?? 0,
        protein: double.tryParse(_macroControllers['protein']!.text) ?? 0,
        carbs: double.tryParse(_macroControllers['carbs']!.text) ?? 0,
        fat: double.tryParse(_macroControllers['fat']!.text) ?? 0,
        fiber: double.tryParse(_macroControllers['fiber']!.text) ?? 0,
        sugar: double.tryParse(_macroControllers['sugar']!.text) ?? 0,
        saturatedFat:
            double.tryParse(_macroControllers['saturatedFat']!.text) ?? 0,
        sodium: double.tryParse(_macroControllers['sodium']!.text) ?? 0,
        potassium: double.tryParse(_macroControllers['potassium']!.text) ?? 0,
        calcium: double.tryParse(_macroControllers['calcium']!.text) ?? 0,
        iron: double.tryParse(_macroControllers['iron']!.text) ?? 0,
        magnesium: double.tryParse(_macroControllers['magnesium']!.text) ?? 0,
        cholesterol:
            double.tryParse(_macroControllers['cholesterol']!.text) ?? 0,
        isDefault: false,
        createdAt: widget.food?.createdAt,
      );

      if (widget.food == null) {
        await ref.read(foodNotifierProvider.notifier).addFood(food);
      } else {
        await ref.read(foodNotifierProvider.notifier).updateFood(food);
      }

      if (mounted) {
        Navigator.pop(context);
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
        title: Text(
          widget.food == null
              ? 'Add Food'
              : _isStandardFood
                  ? 'Standard Food'
                  : 'Edit Food',
        ),
        actions: [
          if (!_isStandardFood)
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info
            const Text(
              'Basic Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              readOnly: _isStandardFood,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _defaultQtyController,
                    readOnly: _isStandardFood,
                    decoration: const InputDecoration(
                      labelText: 'Default Qty',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _incrementByController,
                    readOnly: _isStandardFood,
                    decoration: const InputDecoration(
                      labelText: 'Increment By',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _unitController,
              readOnly: _isStandardFood,
              decoration: const InputDecoration(
                labelText: 'Unit (e.g. cup, g)',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Macros
            const Text(
              'Nutrition Facts (per 1 unit)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._macros.map((m) {
              final (key, label, unit) = m;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _macroControllers[key],
                  readOnly: _isStandardFood,
                  decoration: InputDecoration(
                    labelText: label,
                    suffixText: unit,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
