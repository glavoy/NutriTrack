import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(calorieHistoryProvider(30));
    final targets = ref.watch(userTargetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start tracking your meals to see your progress',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final sortedDates = history.keys.toList()
            ..sort((a, b) => a.compareTo(b));

          final targetCalories = targets.when(
            data: (t) => t.calories,
            loading: () => 2100.0,
            error: (_, __) => 2100.0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calories - Last 30 Days',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 500,
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 || index >= sortedDates.length) {
                                        return const SizedBox();
                                      }
                                      if (index % 7 != 0) return const SizedBox();
                                      return Text(
                                        DateFormat('M/d').format(sortedDates[index]),
                                        style: const TextStyle(fontSize: 10),
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
                                    color: Colors.green.withOpacity(0.5),
                                    strokeWidth: 2,
                                    dashArray: [5, 5],
                                    label: HorizontalLineLabel(
                                      show: true,
                                      labelResolver: (_) => 'Target',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: sortedDates.asMap().entries.map((e) {
                                    return FlSpot(
                                      e.key.toDouble(),
                                      history[e.value] ?? 0,
                                    );
                                  }).toList(),
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.primary,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                ...sortedDates.reversed.map((date) {
                  final calories = history[date] ?? 0;
                  final percentage = (calories / targetCalories * 100).round();
                  final isOver = calories > targetCalories;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isOver
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
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
