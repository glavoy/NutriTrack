import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
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
    final entriesAsync = ref.watch(entriesProvider);
    final entries = entriesAsync.value ?? [];

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
          _NutrientProgress(
            label: 'Calories',
            current: totals.calories,
            target: targets.calories,
            unit: 'kcal',
            isLimit: false,
            entryValue: (entry) => entry.calories,
          ),
          _NutrientProgress(
            label: 'Protein',
            current: totals.protein,
            target: targets.protein,
            unit: 'g',
            isLimit: false,
            entryValue: (entry) => entry.protein,
          ),
          _NutrientProgress(
            label: 'Carbs',
            current: totals.carbs,
            target: targets.carbs,
            unit: 'g',
            isLimit: false,
            entryValue: (entry) => entry.carbs,
          ),
          _NutrientProgress(
            label: 'Fat',
            current: totals.fat,
            target: targets.fat,
            unit: 'g',
            isLimit: false,
            entryValue: (entry) => entry.fat,
          ),
          _NutrientProgress(
            label: 'Fiber',
            current: totals.fiber,
            target: targets.fiber,
            unit: 'g',
            isLimit: false,
            entryValue: (entry) => entry.fiber,
          ),
          _NutrientProgress(
            label: 'Sugar',
            current: totals.sugar,
            target: targets.sugar,
            unit: 'g',
            isLimit: true,
            entryValue: (entry) => entry.sugar,
          ),
        ];

        final secondaryNutrients = [
          _NutrientProgress(
            label: 'Sat Fat',
            current: totals.saturatedFat,
            target: targets.saturatedFat,
            unit: 'g',
            isLimit: true,
            entryValue: (entry) => entry.saturatedFat,
          ),
          _NutrientProgress(
            label: 'Sodium',
            current: totals.sodium,
            target: targets.sodium,
            unit: 'mg',
            isLimit: true,
            entryValue: (entry) => entry.sodium,
          ),
          _NutrientProgress(
            label: 'Potassium',
            current: totals.potassium,
            target: targets.potassium,
            unit: 'mg',
            isLimit: false,
            entryValue: (entry) => entry.potassium,
          ),
          _NutrientProgress(
            label: 'Calcium',
            current: totals.calcium,
            target: targets.calcium,
            unit: 'mg',
            isLimit: false,
            entryValue: (entry) => entry.calcium,
          ),
          _NutrientProgress(
            label: 'Iron',
            current: totals.iron,
            target: targets.iron,
            unit: 'mg',
            isLimit: false,
            entryValue: (entry) => entry.iron,
          ),
          _NutrientProgress(
            label: 'Magnesium',
            current: totals.magnesium,
            target: targets.magnesium,
            unit: 'mg',
            isLimit: false,
            entryValue: (entry) => entry.magnesium,
          ),
          _NutrientProgress(
            label: 'Cholesterol',
            current: totals.cholesterol,
            target: targets.cholesterol,
            unit: 'mg',
            isLimit: true,
            entryValue: (entry) => entry.cholesterol,
          ),
        ];

        return Card(
          color: const Color(0xFFFBFCFA),
          surfaceTintColor: Colors.transparent,
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
                      progress: n,
                      entries: entries,
                    )),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...secondaryNutrients.map((n) => _NutrientRow(
                        progress: n,
                        entries: entries,
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

class _NutrientProgress {
  final String label;
  final double current;
  final double target;
  final String unit;
  final bool isLimit;
  final double Function(Entry entry) entryValue;

  const _NutrientProgress({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.isLimit,
    required this.entryValue,
  });
}

class _NutrientRow extends StatefulWidget {
  final _NutrientProgress progress;
  final List<Entry> entries;

  const _NutrientRow({
    required this.progress,
    required this.entries,
  });

  @override
  State<_NutrientRow> createState() => _NutrientRowState();
}

class _NutrientRowState extends State<_NutrientRow> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  List<_BreakdownItem> _items() {
    final values = <String, double>{};
    for (final entry in widget.entries) {
      final value = widget.progress.entryValue(entry);
      if (value <= 0) continue;
      values.update(
        entry.foodName,
        (existing) => existing + value,
        ifAbsent: () => value,
      );
    }

    final items = values.entries
        .map((entry) => _BreakdownItem(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (items.length <= 5) return items;

    final topItems = items.take(5).toList();
    final other =
        items.skip(5).fold<double>(0, (sum, item) => sum + item.value);
    return [...topItems, _BreakdownItem('Other', other)];
  }

  void _showOverlay() {
    if (_overlayEntry != null || widget.progress.current <= 0) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surface,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _BreakdownContent(
                        label: widget.progress.label,
                        unit: widget.progress.unit,
                        total: widget.progress.current,
                        items: _items(),
                        compact: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showBreakdownSheet() {
    _removeOverlay();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _BreakdownContent(
              label: widget.progress.label,
              unit: widget.progress.unit,
              total: widget.progress.current,
              items: _items(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.progress.target > 0
        ? (widget.progress.current / widget.progress.target).clamp(0.0, 1.0)
        : 0.0;

    Color progressColor() {
      final current = widget.progress.current;
      final target = widget.progress.target;
      final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
      final lightness = 0.9 - (progress * 0.52);

      if (widget.progress.isLimit) {
        if (current > target) return const Color(0xFF8F332D);
      }

      return HSLColor.fromAHSL(1, 7, 0.55, lightness).toColor();
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showOverlay(),
        onExit: (_) => _removeOverlay(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _showBreakdownSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.progress.label,
                      style: const TextStyle(
                        color: Color(0xFF6D746C),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${widget.progress.current.round()} / '
                      '${widget.progress.target.round()} ${widget.progress.unit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: const Color(0xFFE9EDE7),
                    valueColor: AlwaysStoppedAnimation(progressColor()),
                    minHeight: 7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final double value;

  const _BreakdownItem(this.label, this.value);
}

class _BreakdownContent extends StatelessWidget {
  final String label;
  final String unit;
  final double total;
  final List<_BreakdownItem> items;
  final bool compact;

  const _BreakdownContent({
    required this.label,
    required this.unit,
    required this.total,
    required this.items,
    this.compact = false,
  });

  static const _colors = [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFF57C00),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFF607D8B),
  ];

  String _formatValue(double value) {
    if (unit == 'kcal') return '${value.round()} $unit';
    if (value >= 10) return '${value.round()} $unit';
    return '${double.parse(value.toStringAsFixed(1))} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final chartSize = compact ? 110.0 : 150.0;
    final titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: compact ? 14 : 18,
    );

    if (items.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label breakdown', style: titleStyle),
          const SizedBox(height: 12),
          Text(
            'No logged foods contribute to this nutrient.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label breakdown', style: titleStyle),
        const SizedBox(height: 4),
        Text(
          'Total: ${_formatValue(total)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: chartSize,
              height: chartSize,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: chartSize * 0.24,
                  sectionsSpace: 2,
                  sections: [
                    for (var i = 0; i < items.length; i++)
                      PieChartSectionData(
                        value: items[i].value,
                        title: '',
                        radius: chartSize * 0.34,
                        color: _colors[i % _colors.length],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++)
                    _BreakdownLegendRow(
                      color: _colors[i % _colors.length],
                      item: items[i],
                      total: total,
                      formattedValue: _formatValue(items[i].value),
                      compact: compact,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BreakdownLegendRow extends StatelessWidget {
  final Color color;
  final _BreakdownItem item;
  final double total;
  final String formattedValue;
  final bool compact;

  const _BreakdownLegendRow({
    required this.color,
    required this.item,
    required this.total,
    required this.formattedValue,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? item.value / total * 100 : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: compact ? 12 : 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$formattedValue (${percentage.round()}%)',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
