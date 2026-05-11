import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/daily_progress_card.dart';
import '../widgets/meal_card.dart';
import '../widgets/quick_add_sheet.dart';
import 'history_screen.dart';
import 'manage_foods_screen.dart';
import 'settings_screen.dart';
import '../services/supabase_service.dart';
import '../services/local_database.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Sync pending entries when app starts
    Future.microtask(() {
      ref.read(syncServiceProvider).syncPendingEntries();
    });
  }

  void _showQuickAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickAddSheet(),
    );
  }

  Future<void> _selectDate() async {
    final currentDate = ref.read(selectedDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }

  void _goToToday() {
    ref.read(selectedDateProvider.notifier).state = DateTime.now();
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
      await SupabaseService().signOut();
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final entriesByMeal = ref.watch(entriesByMealProvider);
    final entriesAsync = ref.watch(entriesProvider);
    final isToday = _isToday(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageFoodsScreen()),
              );
            },
            tooltip: 'Manage Foods',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            tooltip: 'History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(entriesProvider);
          ref.invalidate(foodsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Date selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        ref.read(selectedDateProvider.notifier).state =
                            selectedDate.subtract(const Duration(days: 1));
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                isToday
                                    ? 'Today'
                                    : DateFormat('EEE, MMM d')
                                        .format(selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: isToday
                          ? null
                          : () {
                              ref.read(selectedDateProvider.notifier).state =
                                  selectedDate.add(const Duration(days: 1));
                            },
                    ),
                    if (!isToday)
                      TextButton(
                        onPressed: _goToToday,
                        child: const Text('Today'),
                      ),
                  ],
                ),
              ),
            ),

            // Daily progress card
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: DailyProgressCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Meals
            entriesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $e')),
              ),
              data: (_) => SliverList(
                delegate: SliverChildListDelegate([
                  for (final meal in Meal.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: MealCard(
                        meal: meal,
                        entries: entriesByMeal[meal] ?? [],
                        onAddPressed: () {
                          ref.read(selectedMealProvider.notifier).state = meal;
                          _showQuickAdd();
                        },
                      ),
                    ),
                  const SizedBox(height: 100), // Space for FAB
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
      ),
    );
  }
}
