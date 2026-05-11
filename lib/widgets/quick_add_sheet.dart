import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Food',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Meal selector
          const _MealSelector(),
          const SizedBox(height: 8),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Quick Add'),
              Tab(text: 'Custom'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _QuickAddTab(),
                _CustomEntryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSelector extends ConsumerWidget {
  const _MealSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMeal = ref.watch(selectedMealProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<Meal>(
        segments: Meal.values.map((meal) {
          return ButtonSegment(
            value: meal,
            label: Text(meal.displayName),
          );
        }).toList(),
        selected: {selectedMeal},
        onSelectionChanged: (selection) {
          ref.read(selectedMealProvider.notifier).state = selection.first;
        },
      ),
    );
  }
}

class _QuickAddTab extends ConsumerWidget {
  const _QuickAddTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodsAsync = ref.watch(filteredFoodsProvider);
    final searchQuery = ref.watch(foodSearchQueryProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search foods...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ref.read(foodSearchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              ref.read(foodSearchQueryProvider.notifier).state = value;
            },
          ),
        ),

        // Foods list
        Expanded(
          child: foodsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (foods) {
              if (foods.isEmpty) {
                return const Center(
                  child: Text('No foods found'),
                );
              }

              return ListView.builder(
                itemCount: foods.length,
                itemBuilder: (context, index) {
                  final food = foods[index];
                  return _FoodTile(food: food);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FoodTile extends ConsumerStatefulWidget {
  final Food food;

  const _FoodTile({required this.food});

  @override
  ConsumerState<_FoodTile> createState() => _FoodTileState();
}

class _FoodTileState extends ConsumerState<_FoodTile> {
  late double _quantity;
  late final TextEditingController _quantityController;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.food.defaultQty;
    _quantityController = TextEditingController(text: _formatQty(_quantity));
  }

  @override
  void didUpdateWidget(covariant _FoodTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.food.id != widget.food.id) {
      _quantity = widget.food.defaultQty;
      _quantityController.text = _formatQty(_quantity);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  String _formatQty(double quantity) {
    if (quantity % 1 == 0) return quantity.toInt().toString();
    return double.parse(quantity.toStringAsFixed(3)).toString();
  }

  void _setQuantity(double quantity) {
    _quantity = double.parse(quantity.toStringAsFixed(3));
    _quantityController.text = _formatQty(_quantity);
  }

  void _addEntry() async {
    final selectedDate = ref.read(selectedDateProvider);
    final selectedMeal = ref.read(selectedMealProvider);
    final nutrients = widget.food.scaledNutrients(_quantity);

    final entry = Entry(
      date: selectedDate,
      meal: selectedMeal,
      foodName: widget.food.name,
      quantity: _quantity,
      unit: widget.food.unit,
      foodId: widget.food.id,
      calories: nutrients['calories']!,
      fat: nutrients['fat']!,
      saturatedFat: nutrients['saturatedFat']!,
      carbs: nutrients['carbs']!,
      fiber: nutrients['fiber']!,
      sugar: nutrients['sugar']!,
      protein: nutrients['protein']!,
      sodium: nutrients['sodium']!,
      potassium: nutrients['potassium']!,
      calcium: nutrients['calcium']!,
      iron: nutrients['iron']!,
      magnesium: nutrients['magnesium']!,
      cholesterol: nutrients['cholesterol']!,
    );

    await ref.read(entryNotifierProvider.notifier).addEntry(entry);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${widget.food.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nutrients = widget.food.scaledNutrients(_quantity);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.food.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${widget.food.calories.toStringAsFixed(2)} kcal per ${widget.food.unit} '
              '• default ${_formatQty(widget.food.defaultQty)} ${widget.food.unit}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _quantity > widget.food.incrementBy
                      ? () => setState(() {
                            _setQuantity(_quantity - widget.food.incrementBy);
                          })
                      : null,
                ),
                SizedBox(
                  width: 50,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    controller: _quantityController,
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() => _quantity = parsed);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() {
                    _setQuantity(_quantity + widget.food.incrementBy);
                  }),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addEntry,
                  child: const Text('Add'),
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),

          // Expanded nutrient details
          if (_expanded || _quantity != widget.food.defaultQty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _NutrientChip(
                    label: 'Cal',
                    value: nutrients['calories']!.round().toString(),
                  ),
                  _NutrientChip(
                    label: 'P',
                    value: '${nutrients['protein']!.round()}g',
                  ),
                  _NutrientChip(
                    label: 'C',
                    value: '${nutrients['carbs']!.round()}g',
                  ),
                  _NutrientChip(
                    label: 'F',
                    value: '${nutrients['fat']!.round()}g',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;

  const _NutrientChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _CustomEntryTab extends ConsumerStatefulWidget {
  const _CustomEntryTab();

  @override
  ConsumerState<_CustomEntryTab> createState() => _CustomEntryTabState();
}

class _CustomEntryTabState extends ConsumerState<_CustomEntryTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sugarController = TextEditingController();
  final _sodiumController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final selectedDate = ref.read(selectedDateProvider);
      final selectedMeal = ref.read(selectedMealProvider);

      final entry = Entry(
        date: selectedDate,
        meal: selectedMeal,
        foodName: _nameController.text.trim(),
        quantity: 1,
        unit: 'serving',
        calories: double.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        fiber: double.tryParse(_fiberController.text) ?? 0,
        sugar: double.tryParse(_sugarController.text) ?? 0,
        sodium: double.tryParse(_sodiumController.text) ?? 0,
      );

      await ref.read(entryNotifierProvider.notifier).addEntry(entry);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${entry.foodName}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food name',
                hintText: 'e.g., Grilled chicken salad',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories',
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    decoration: const InputDecoration(
                      labelText: 'Protein',
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    decoration: const InputDecoration(
                      labelText: 'Carbs',
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    decoration: const InputDecoration(
                      labelText: 'Fat',
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fiberController,
                    decoration: const InputDecoration(
                      labelText: 'Fiber',
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sugarController,
                    decoration: const InputDecoration(
                      labelText: 'Sugar',
                      suffixText: 'g',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sodiumController,
                    decoration: const InputDecoration(
                      labelText: 'Sodium',
                      suffixText: 'mg',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
