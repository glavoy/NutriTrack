import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'supabase_service.dart';
import 'local_database.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _supabase = SupabaseService();
  final _local = LocalDatabase.instance;
  final _uuid = const Uuid();

  bool _isSyncing = false;

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ==================== FOODS ====================

  Future<List<Food>> getFoods() async {
    if (await isOnline()) {
      try {
        final foods = await _supabase.getFoods();
        // Only update cache if we actually got foods back
        if (foods.isNotEmpty) {
          await _local.cacheFoods(foods);
        }
        return foods;
      } catch (e) {
        // If Supabase fails, fall back to whatever is in the local cache
        final cached = await _local.getCachedFoods();
        if (cached.isEmpty) rethrow; // If both fail, show the error
        return cached;
      }
    } else {
      return await _local.getCachedFoods();
    }
  }

  Future<void> addFood(Food food) async {
    // Optimistic update could go here, but for now we'll stick to online-first for foods
    // since we want the ID from Supabase.
    // However, if we want offline support, we'd generate a local ID.
    // Let's assume online for management for now, but handle the sync properly.

    if (await isOnline()) {
      await _supabase.addFood(food);
      // We don't need to manually update cache here because invalidating the provider
      // will trigger getFoods() which refreshes the cache.
    } else {
      throw Exception('Must be online to manage foods');
    }
  }

  Future<void> updateFood(Food food) async {
    if (await isOnline()) {
      await _supabase.updateFood(food);
    } else {
      throw Exception('Must be online to manage foods');
    }
  }

  Future<void> deleteFood(String id) async {
    if (await isOnline()) {
      await _supabase.deleteFood(id);
    } else {
      throw Exception('Must be online to manage foods');
    }
  }

  Future<int> recalculateEntriesForFood(Food food) async {
    final foodId = food.id;
    if (foodId == null) {
      throw ArgumentError('Food must have an id before entries can be updated');
    }
    if (!await isOnline()) {
      throw Exception('Must be online to recalculate logged entries');
    }

    final entries = await _supabase.getEntriesForFood(foodId);
    await _local.saveEntriesLocally(entries, isSynced: true);
    if (entries.isEmpty) return 0;

    final recalculatedEntries = entries.map((entry) {
      final nutrients = food.scaledNutrients(entry.quantity);
      return entry.copyWith(
        foodName: food.name,
        unit: food.unit,
        calories: nutrients['calories'],
        fat: nutrients['fat'],
        saturatedFat: nutrients['saturatedFat'],
        carbs: nutrients['carbs'],
        fiber: nutrients['fiber'],
        sugar: nutrients['sugar'],
        protein: nutrients['protein'],
        sodium: nutrients['sodium'],
        potassium: nutrients['potassium'],
        calcium: nutrients['calcium'],
        iron: nutrients['iron'],
        magnesium: nutrients['magnesium'],
        cholesterol: nutrients['cholesterol'],
      );
    }).toList();

    await _supabase.updateEntries(recalculatedEntries);
    await _local.saveEntriesLocally(recalculatedEntries, isSynced: true);

    return recalculatedEntries.length;
  }
  // ==================== ENTRIES ====================

  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    if (await isOnline()) {
      try {
        final entries = await _supabase.getEntriesForDate(date);

        // Update local cache
        await _local.clearLocalEntriesForDate(date);
        for (final entry in entries) {
          await _local.saveEntryLocally(entry, isSynced: true);
        }

        return entries;
      } catch (e) {
        return await _local.getLocalEntriesForDate(date);
      }
    } else {
      return await _local.getLocalEntriesForDate(date);
    }
  }

  Future<Entry> addEntry(Entry entry) async {
    // Generate local ID if needed
    final entryWithId =
        entry.id == null ? entry.copyWith(id: _uuid.v4()) : entry;

    if (await isOnline()) {
      try {
        final savedEntry = await _supabase.addEntry(entryWithId);
        await _local.saveEntryLocally(savedEntry, isSynced: true);
        return savedEntry;
      } catch (e) {
        await _local.saveEntryLocally(entryWithId, isSynced: false);
        throw Exception(
          'Entry saved locally, but could not sync to Supabase: $e',
        );
      }
    } else {
      // Save locally for later sync
      await _local.saveEntryLocally(entryWithId, isSynced: false);
      return entryWithId;
    }
  }

  Future<void> deleteEntry(String id) async {
    await _local.deleteLocalEntry(id);

    if (await isOnline()) {
      try {
        await _supabase.deleteEntry(id);
      } catch (e) {
        // Entry might not exist on server yet, that's OK
      }
    }
  }

  Future<Entry> updateEntry(Entry entry) async {
    if (await isOnline()) {
      try {
        await _supabase.updateEntry(entry);
        await _local.saveEntryLocally(entry, isSynced: true);
        return entry;
      } catch (e) {
        // Save locally for later sync
        await _local.saveEntryLocally(entry, isSynced: false);
        return entry;
      }
    } else {
      // Save locally for later sync
      await _local.saveEntryLocally(entry, isSynced: false);
      return entry;
    }
  }

  // ==================== SYNC ====================

  Future<void> syncPendingEntries() async {
    if (_isSyncing) return;
    if (!await isOnline()) return;

    _isSyncing = true;

    try {
      final unsyncedEntries = await _local.getUnsyncedEntries();

      for (final entry in unsyncedEntries) {
        try {
          await _supabase.addEntry(entry);
          await _local.markEntrySynced(entry.id!);
        } catch (e) {
          // Skip this entry, try again later
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  // ==================== USER TARGETS ====================

  Future<UserTargets> getUserTargets() async {
    if (await isOnline()) {
      try {
        final targets = await _supabase.getUserTargets();
        await _local.cacheUserTargets(targets);
        return targets;
      } catch (e) {
        final cached = await _local.getCachedUserTargets();
        return cached ?? UserTargets.defaultTargets();
      }
    } else {
      final cached = await _local.getCachedUserTargets();
      return cached ?? UserTargets.defaultTargets();
    }
  }

  Future<void> updateUserTargets(UserTargets targets) async {
    await _local.cacheUserTargets(targets);

    if (await isOnline()) {
      try {
        await _supabase.updateUserTargets(targets);
      } catch (e) {
        // Saved locally, will sync later
      }
    }
  }

  // ==================== HISTORY ====================

  Future<Map<DateTime, double>> getCalorieHistory(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    return getCalorieHistoryForRange(startDate, endDate);
  }

  Future<Map<DateTime, double>> getCalorieHistoryForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    if (await isOnline()) {
      try {
        final history = await _supabase.getCalorieHistoryForRange(
          normalizedStart,
          normalizedEnd,
        );
        final entries = await _supabase.getEntriesForDateRange(
          normalizedStart,
          normalizedEnd,
        );

        for (final entry in entries) {
          await _local.saveEntryLocally(entry, isSynced: true);
        }

        return history;
      } catch (e) {
        return _calorieHistoryFromEntries(
          await _local.getLocalEntriesForDateRange(
              normalizedStart, normalizedEnd),
        );
      }
    }
    return _calorieHistoryFromEntries(
      await _local.getLocalEntriesForDateRange(normalizedStart, normalizedEnd),
    );
  }

  Map<DateTime, double> _calorieHistoryFromEntries(List<Entry> entries) {
    final history = <DateTime, double>{};
    for (final entry in entries) {
      final dateOnly =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      history[dateOnly] = (history[dateOnly] ?? 0) + entry.calories;
    }
    return history;
  }
}
