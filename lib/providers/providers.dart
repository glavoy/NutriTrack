import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/sync_service.dart';
import '../services/supabase_service.dart';

// Services
final syncServiceProvider = Provider((ref) => SyncService());
final supabaseServiceProvider = Provider((ref) => SupabaseService());

// Selected date
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// Foods list
final foodsProvider = FutureProvider<List<Food>>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getFoods();
});

// Entries for selected date
final entriesProvider = FutureProvider<List<Entry>>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  final selectedDate = ref.watch(selectedDateProvider);
  return await syncService.getEntriesForDate(selectedDate);
});

// Daily totals
final dailyTotalsProvider = Provider<DailyTotals>((ref) {
  final entriesAsync = ref.watch(entriesProvider);
  return entriesAsync.when(
    data: (entries) => DailyTotals.fromEntries(entries),
    loading: () => DailyTotals(),
    error: (_, __) => DailyTotals(),
  );
});

// User targets
final userTargetsProvider = FutureProvider<UserTargets>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getUserTargets();
});

// Entries grouped by meal
final entriesByMealProvider = Provider<Map<Meal, List<Entry>>>((ref) {
  final entriesAsync = ref.watch(entriesProvider);
  return entriesAsync.when(
    data: (entries) {
      final grouped = <Meal, List<Entry>>{};
      for (final meal in Meal.values) {
        grouped[meal] = entries.where((e) => e.meal == meal).toList();
      }
      return grouped;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// Calorie history for charts
final calorieHistoryProvider = FutureProvider.family<Map<DateTime, double>, int>((ref, days) async {
  final syncService = ref.watch(syncServiceProvider);
  return await syncService.getCalorieHistory(days);
});

// Entry actions notifier
class EntryNotifier extends StateNotifier<AsyncValue<void>> {
  final SyncService _syncService;
  final Ref _ref;

  EntryNotifier(this._syncService, this._ref) : super(const AsyncValue.data(null));

  Future<void> addEntry(Entry entry) async {
    state = const AsyncValue.loading();
    try {
      await _syncService.addEntry(entry);
      _ref.invalidate(entriesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEntry(String id) async {
    state = const AsyncValue.loading();
    try {
      await _syncService.deleteEntry(id);
      _ref.invalidate(entriesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEntry(Entry entry) async {
    state = const AsyncValue.loading();
    try {
      await _syncService.updateEntry(entry);
      _ref.invalidate(entriesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final entryNotifierProvider = StateNotifierProvider<EntryNotifier, AsyncValue<void>>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return EntryNotifier(syncService, ref);
});

// Food actions notifier
class FoodNotifier extends StateNotifier<AsyncValue<void>> {
  final SyncService _syncService;
  final Ref _ref;

  FoodNotifier(this._syncService, this._ref) : super(const AsyncValue.data(null));

  Future<void> addFood(Food food) async {
    state = const AsyncValue.loading();
    try {
      await _syncService.addFood(food);
      _ref.invalidate(foodsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFood(String id) async {
    state = const AsyncValue.loading();
    try {
      await _syncService.deleteFood(id);
      _ref.invalidate(foodsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFood(Food food) async {
    state = const AsyncValue.loading();
    try {
      await _syncService.updateFood(food);
      _ref.invalidate(foodsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final foodNotifierProvider = StateNotifierProvider<FoodNotifier, AsyncValue<void>>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return FoodNotifier(syncService, ref);
});

// Selected meal for quick add
final selectedMealProvider = StateProvider<Meal>((ref) => Meal.breakfast);

// Search query for foods
final foodSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered foods based on search
final filteredFoodsProvider = Provider<AsyncValue<List<Food>>>((ref) {
  final foodsAsync = ref.watch(foodsProvider);
  final query = ref.watch(foodSearchQueryProvider).toLowerCase();
  
  return foodsAsync.whenData((foods) {
    if (query.isEmpty) return foods;
    return foods.where((f) => f.name.toLowerCase().contains(query)).toList();
  });
});
