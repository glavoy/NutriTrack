import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/local_database.dart';

class MealCard extends ConsumerWidget {
  final Meal meal;
  final List<Entry> entries;
  final VoidCallback onAddPressed;

  const MealCard({
    super.key,
    required this.meal,
    required this.entries,
    required this.onAddPressed,
  });

  IconData _getMealIcon() {
    switch (meal) {
      case Meal.breakfast:
        return Icons.free_breakfast;
      case Meal.lunch:
        return Icons.lunch_dining;
      case Meal.dinner:
        return Icons.dinner_dining;
      case Meal.snack:
        return Icons.icecream;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCalories = entries.fold<double>(0, (sum, e) => sum + e.calories);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: Icon(
              _getMealIcon(),
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              meal.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${totalCalories.round()} kcal',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAddPressed,
                  tooltip: 'Add food',
                ),
              ],
            ),
          ),

          // Entries list
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No items logged',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _EntryTile(entry: entry);
              },
            ),
        ],
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  final Entry entry;

  const _EntryTile({required this.entry});

  void _showContextMenu(BuildContext context, WidgetRef ref, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'edit') {
        _showEditDialog(context, ref);
      } else if (value == 'delete') {
        _showDeleteDialog(context, ref);
      }
    });
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Remove "${entry.foodName}" from your log?'),
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

    if (confirmed == true && entry.id != null) {
      ref.read(entryNotifierProvider.notifier).deleteEntry(entry.id!);
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref) async {
    // Fetch the food definition to get the correct increment step
    Food? food;
    if (entry.foodId != null) {
      final foods = await LocalDatabase.instance.getCachedFoods();
      try {
        food = foods.firstWhere((f) => f.id == entry.foodId);
      } catch (_) {
        // Food not found in cache
      }
    }

    // Determine step size
    double step = 0.5;
    if (food != null) {
      step = food.incrementBy;
    } else {
      // Fallback heuristics if food not found
      if (entry.unit == 'cup' || entry.unit.startsWith('cup ')) step = 0.25;
      if (entry.unit == 'g' || entry.unit == 'ml') step = 10.0;
    }

    // Helper to format double to string
    String formatQty(double qty) {
      if (qty % 1 == 0) return qty.toInt().toString();
      // Avoid long decimals
      return double.parse(qty.toStringAsFixed(3)).toString();
    }

    final quantityController =
        TextEditingController(text: formatQty(entry.quantity));

    // Calculate per-unit values from current entry
    // We use the entry's values to preserve the specific log (e.g. if nutrients changed since then)
    final perUnitCalories = entry.quantity > 0 ? entry.calories / entry.quantity : 0;
    final perUnitProtein = entry.quantity > 0 ? entry.protein / entry.quantity : 0;
    final perUnitCarbs = entry.quantity > 0 ? entry.carbs / entry.quantity : 0;
    final perUnitFat = entry.quantity > 0 ? entry.fat / entry.quantity : 0;

    if (!context.mounted) return;

    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        double previewQty = entry.quantity;
        return StatefulBuilder(
          builder: (context, setState) {
            final previewCalories = (perUnitCalories * previewQty).round();
            return AlertDialog(
              title: const Text('Edit Quantity'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.foodName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: previewQty > step
                            ? () {
                                setState(() {
                                  previewQty -= step;
                                  if (previewQty < 0) previewQty = 0;
                                  // Fix precision
                                  previewQty = double.parse(previewQty.toStringAsFixed(3));
                                  quantityController.text = formatQty(previewQty);
                                });
                              }
                            : null,
                      ),
                      const SizedBox(width: 8),
                      // Text Field
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: quantityController,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 4),
                            border: OutlineInputBorder(),
                            // Unit removed from here
                          ),
                          onChanged: (value) {
                            final parsed = double.tryParse(value);
                            if (parsed != null && parsed >= 0) {
                              setState(() => previewQty = parsed);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unit Text Displayed Outside
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 60),
                        child: Text(
                          entry.unit,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          setState(() {
                            previewQty += step;
                            // Fix precision
                            previewQty = double.parse(previewQty.toStringAsFixed(3));
                            quantityController.text = formatQty(previewQty);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$previewCalories kcal',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'P: ${(perUnitProtein * previewQty).round()}g  '
                          'C: ${(perUnitCarbs * previewQty).round()}g  '
                          'F: ${(perUnitFat * previewQty).round()}g',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, previewQty),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && entry.id != null && result != entry.quantity) {
      final ratio = entry.quantity > 0 ? result / entry.quantity : 0;
      // Recalculate based on per-unit to be safe, or just use ratio
      final updatedEntry = entry.copyWith(
        quantity: result,
        calories: entry.calories * ratio,
        protein: entry.protein * ratio,
        carbs: entry.carbs * ratio,
        fat: entry.fat * ratio,
        fiber: entry.fiber * ratio,
        sugar: entry.sugar * ratio,
        saturatedFat: entry.saturatedFat * ratio,
        sodium: entry.sodium * ratio,
        potassium: entry.potassium * ratio,
        calcium: entry.calcium * ratio,
        iron: entry.iron * ratio,
        magnesium: entry.magnesium * ratio,
        cholesterol: entry.cholesterol * ratio,
      );
      ref.read(entryNotifierProvider.notifier).updateEntry(updatedEntry);
    }

    quantityController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onSecondaryTapDown: (details) {
        // Right-click on Windows/desktop
        _showContextMenu(context, ref, details.globalPosition);
      },
      onLongPressStart: (details) {
        // Long press on Android/touch devices
        _showContextMenu(context, ref, details.globalPosition);
      },
      child: ListTile(
        dense: true,
        title: Text(entry.foodName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!entry.foodName.endsWith(' ${entry.unit})'))
              Text(
                '${entry.quantity % 1 == 0 ? entry.quantity.toInt() : entry.quantity} ${entry.unit}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            Text(
              'P: ${entry.protein.round()}g  C: ${entry.carbs.round()}g  F: ${entry.fat.round()}g',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Text(
          '${entry.calories.round()} kcal',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
