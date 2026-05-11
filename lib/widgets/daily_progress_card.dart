import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class DailyProgressCard extends ConsumerStatefulWidget {
  const DailyProgressCard({super.key});

  @override
  ConsumerState<DailyProgressCard> createState() => _DailyProgressCardState();
}

class _DailyProgressCardState extends ConsumerState<DailyProgressCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(dailyTotalsProvider);
    final targetsAsync = ref.watch(userTargetsProvider);

    return targetsAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
      ),
      data: (targets) {
        final primaryNutrients = [
          ('Calories', totals.calories, targets.calories, 'kcal', false),
          ('Protein', totals.protein, targets.protein, 'g', false),
          ('Carbs', totals.carbs, targets.carbs, 'g', false),
          ('Fat', totals.fat, targets.fat, 'g', false),
          ('Fiber', totals.fiber, targets.fiber, 'g', false),
          ('Sugar', totals.sugar, targets.sugar, 'g', true),
        ];

        final secondaryNutrients = [
          ('Sat Fat', totals.saturatedFat, targets.saturatedFat, 'g', true),
          ('Sodium', totals.sodium, targets.sodium, 'mg', true),
          ('Potassium', totals.potassium, targets.potassium, 'mg', false),
          ('Calcium', totals.calcium, targets.calcium, 'mg', false),
          ('Iron', totals.iron, targets.iron, 'mg', false),
          ('Magnesium', totals.magnesium, targets.magnesium, 'mg', false),
          ('Cholesterol', totals.cholesterol, targets.cholesterol, 'mg', true),
        ];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _expanded = !_expanded);
                      },
                      icon: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                      ),
                      label: Text(_expanded ? 'Less' : 'More'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...primaryNutrients.map((n) => _NutrientRow(
                      label: n.$1,
                      current: n.$2,
                      target: n.$3,
                      unit: n.$4,
                      isLimit: n.$5,
                    )),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...secondaryNutrients.map((n) => _NutrientRow(
                        label: n.$1,
                        current: n.$2,
                        target: n.$3,
                        unit: n.$4,
                        isLimit: n.$5,
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final String unit;
  final bool isLimit;

  const _NutrientRow({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.isLimit,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (current / target).clamp(0.0, 1.0);
    final displayPercentage = (current / target * 100).round();

    Color getColor() {
      if (isLimit) {
        if (current > target) return Colors.red;
        if (current > target * 0.8) return Colors.orange;
        return Colors.green;
      } else {
        if (current >= target) return Colors.green;
        if (current >= target * 0.7) return Colors.orange;
        return Theme.of(context).colorScheme.primary;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              Text(
                '${current.round()} / ${target.round()} $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(getColor()),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
