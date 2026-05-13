import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;
  String? get currentUserEmail => _client.auth.currentUser?.email;

  // ==================== AUTH ====================

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ==================== FOODS ====================

  Future<List<Food>> getFoods() async {
    final response = await _client.from('foods').select().order('name');

    return (response as List).map((json) => Food.fromJson(json)).toList();
  }

  Future<Food> addFood(Food food) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Must be signed in to add foods');
    }

    final data = food.toJson();
    data['user_id'] = userId;
    data['is_default'] = false;

    final response = await _client.from('foods').insert(data).select().single();

    return Food.fromJson(response);
  }

  Future<void> updateFood(Food food) async {
    await _client.from('foods').update(food.toJson()).eq('id', food.id!);
  }

  Future<void> deleteFood(String id) async {
    await _client.from('foods').delete().eq('id', id);
  }

  // ==================== ENTRIES ====================

  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];

    final response = await _client
        .from('entries')
        .select()
        .eq('date', dateStr)
        .order('created_at');

    return (response as List).map((json) => Entry.fromJson(json)).toList();
  }

  Future<List<Entry>> getEntriesForDateRange(
      DateTime start, DateTime end) async {
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    final response = await _client
        .from('entries')
        .select()
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date', ascending: false);

    return (response as List).map((json) => Entry.fromJson(json)).toList();
  }

  Future<List<Entry>> getEntriesForFood(String foodId) async {
    final response = await _client
        .from('entries')
        .select()
        .eq('food_id', foodId)
        .order('date', ascending: false);

    return (response as List).map((json) => Entry.fromJson(json)).toList();
  }

  Future<Entry> addEntry(Entry entry) async {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('Must be signed in to add entries');
    }

    final data = entry.toJson();
    data['user_id'] = userId;

    final response =
        await _client.from('entries').insert(data).select().single();

    return Entry.fromJson(response);
  }

  Future<void> updateEntry(Entry entry) async {
    await _client.from('entries').update(entry.toJson()).eq('id', entry.id!);
  }

  Future<void> updateEntries(List<Entry> entries) async {
    for (final entry in entries) {
      await updateEntry(entry);
    }
  }

  Future<void> deleteEntry(String id) async {
    await _client.from('entries').delete().eq('id', id);
  }

  Future<void> deleteEntriesForDate(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    await _client
        .from('entries')
        .delete()
        .eq('date', dateStr)
        .eq('user_id', currentUserId!);
  }

  // ==================== USER TARGETS ====================

  Future<UserTargets> getUserTargets() async {
    try {
      final response = await _client
          .from('user_targets')
          .select()
          .eq('user_id', currentUserId!)
          .single();

      return UserTargets.fromJson(response);
    } catch (e) {
      // Return defaults if not found
      return UserTargets.defaultTargets();
    }
  }

  Future<void> updateUserTargets(UserTargets targets) async {
    final data = targets.toJson();
    data['user_id'] = currentUserId;

    await _client.from('user_targets').upsert(data, onConflict: 'user_id');
  }

  // ==================== HISTORY / STATS ====================

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

    final entries =
        await getEntriesForDateRange(normalizedStart, normalizedEnd);

    final Map<DateTime, double> history = {};
    for (final entry in entries) {
      final dateOnly =
          DateTime(entry.date.year, entry.date.month, entry.date.day);
      history[dateOnly] = (history[dateOnly] ?? 0) + entry.calories;
    }

    return history;
  }
}
