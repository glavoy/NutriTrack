import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _endDate = today;
    _startDate = today.subtract(const Duration(days: 29));
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );

    if (picked != null) {
      setState(() => _startDate = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _pickEndDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: today,
    );

    if (picked != null) {
      setState(() => _endDate = DateUtils.dateOnly(picked));
    }
  }

  List<DateTime> _datesInRange() {
    final days = _endDate.difference(_startDate).inDays;
    return [
      for (var i = 0; i <= days; i++) _startDate.add(Duration(days: i)),
    ];
  }

  String _rangeLabel() {
    final sameYear = _startDate.year == _endDate.year;
    final startPattern = sameYear ? 'MMM d' : 'MMM d, y';
    return '${DateFormat(startPattern).format(_startDate)} - '
        '${DateFormat('MMM d, y').format(_endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    final range = (start: _startDate, end: _endDate);
    final historyAsync = ref.watch(calorieHistoryRangeProvider(range));
    final targets = ref.watch(userTargetsProvider);

    final targetCalories = targets.when(
      data: (t) => t.calories,
      loading: () => 2100.0,
      error: (_, __) => 2100.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (history) {
          final dates = _datesInRange();
          final trackedDates = history.keys.toList()
            ..sort((a, b) => b.compareTo(a));
          final totalCalories = history.values.fold<double>(
            0,
            (sum, calories) => sum + calories,
          );
          final averageCalories =
              trackedDates.isEmpty ? 0.0 : totalCalories / trackedDates.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateRangeCard(
                  rangeLabel: _rangeLabel(),
                  startDate: _startDate,
                  endDate: _endDate,
                  onPickStart: _pickStartDate,
                  onPickEnd: _pickEndDate,
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  averageCalories: averageCalories,
                  trackedDays: trackedDates.length,
                  totalDays: dates.length,
                ),
                const SizedBox(height: 12),
                _CaloriesChartCard(
                  dates: dates,
                  history: history,
                  targetCalories: targetCalories,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Daily Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                if (trackedDates.isEmpty)
                  const _EmptyHistory()
                else
                  ...trackedDates.map((date) {
                    final calories = history[date] ?? 0;
                    final percentage =
                        (calories / targetCalories * 100).round();
                    final isOver = calories > targetCalories;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isOver ? Colors.red : Colors.green)
                              .withValues(alpha: 0.1),
                          child: Icon(
                            isOver ? Icons.trending_up : Icons.check,
                            color: isOver ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(
                          DateFormat('EEEE, MMM d').format(date),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('$percentage% of target'),
                        trailing: Text(
                          '${calories.round()} kcal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOver ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateRangeCard extends StatelessWidget {
  final String rangeLabel;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const _DateRangeCard({
    required this.rangeLabel,
    required this.startDate,
    required this.endDate,
    required this.onPickStart,
    required this.onPickEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rangeLabel,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'Start',
                    date: startDate,
                    onPressed: onPickStart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: 'End',
                    date: endDate,
                    onPressed: onPickEnd,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onPressed;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
          Text(DateFormat('MMM d, y').format(date)),
        ],
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double averageCalories;
  final int trackedDays;
  final int totalDays;

  const _SummaryRow({
    required this.averageCalories,
    required this.trackedDays,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Average',
            value: averageCalories.round().toString(),
            unit: 'kcal/day',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Tracked',
            value: '$trackedDays',
            unit: 'of $totalDays days',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaloriesChartCard extends StatelessWidget {
  final List<DateTime> dates;
  final Map<DateTime, double> history;
  final double targetCalories;

  const _CaloriesChartCard({
    required this.dates,
    required this.history,
    required this.targetCalories,
  });

  @override
  Widget build(BuildContext context) {
    final maxCalories = history.values.fold<double>(
      targetCalories,
      (maxValue, calories) => math.max(maxValue, calories),
    );
    final maxY = math.max(500, (maxCalories * 1.25 / 250).ceil() * 250);
    final labelInterval = math.max(1, (dates.length / 6).ceil());
    final primaryColor = Theme.of(context).colorScheme.primary;
    final underTargetColor = primaryColor;
    final overTargetColor = Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calories',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Daily total with target line',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 0,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.green, width: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Target ${targetCalories.round()} kcal',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final plotWidth = math.max(1.0, constraints.maxWidth - 52);
                final barWidth = dates.isEmpty
                    ? 8.0
                    : (plotWidth / dates.length * 0.42).clamp(2.0, 10.0);

                return SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18, right: 6),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        minY: 0,
                        maxY: maxY.toDouble(),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor:
                                Theme.of(context).colorScheme.inverseSurface,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            maxContentWidth: 96,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final date = dates[group.x.toInt()];
                              return BarTooltipItem(
                                '${DateFormat('MMM d').format(date)}\n'
                                '${rod.toY.round()} kcal',
                                TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onInverseSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 500,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.7),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 46,
                              interval: 500,
                              getTitlesWidget: (value, meta) {
                                if (value == 0 || value >= maxY) {
                                  return const SizedBox();
                                }
                                return Text(
                                  value.round().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= dates.length) {
                                  return const SizedBox();
                                }
                                if (index % labelInterval != 0 &&
                                    index != dates.length - 1) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    DateFormat('M/d').format(dates[index]),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: targetCalories,
                              color: Colors.green,
                              strokeWidth: 2,
                              dashArray: [6, 4],
                            ),
                          ],
                        ),
                        barGroups: dates.asMap().entries.map((entry) {
                          final calories = history[entry.value] ?? 0;
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: calories,
                                color: calories > targetCalories
                                    ? overTargetColor
                                    : underTargetColor,
                                width: barWidth,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No history in this range',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Choose another date range or start tracking meals.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
