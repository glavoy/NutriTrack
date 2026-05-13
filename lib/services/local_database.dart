import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nutrition_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2 adds increment_by to foods_cache
      // We can simply drop and recreate the cache table
      await db.execute('DROP TABLE IF EXISTS foods_cache');
      await db.execute('''
        CREATE TABLE foods_cache (
          id TEXT PRIMARY KEY,
          user_id TEXT,
          name TEXT NOT NULL,
          unit TEXT NOT NULL,
          default_qty REAL DEFAULT 1,
          increment_by REAL DEFAULT 1,
          calories REAL DEFAULT 0,
          fat REAL DEFAULT 0,
          saturated_fat REAL DEFAULT 0,
          carbs REAL DEFAULT 0,
          fiber REAL DEFAULT 0,
          sugar REAL DEFAULT 0,
          protein REAL DEFAULT 0,
          sodium REAL DEFAULT 0,
          potassium REAL DEFAULT 0,
          calcium REAL DEFAULT 0,
          iron REAL DEFAULT 0,
          magnesium REAL DEFAULT 0,
          cholesterol REAL DEFAULT 0,
          is_default INTEGER DEFAULT 0,
          created_at TEXT
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Foods cache table
    await db.execute('''
      CREATE TABLE foods_cache (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        default_qty REAL DEFAULT 1,
        increment_by REAL DEFAULT 1,
        calories REAL DEFAULT 0,
        fat REAL DEFAULT 0,
        saturated_fat REAL DEFAULT 0,
        carbs REAL DEFAULT 0,
        fiber REAL DEFAULT 0,
        sugar REAL DEFAULT 0,
        protein REAL DEFAULT 0,
        sodium REAL DEFAULT 0,
        potassium REAL DEFAULT 0,
        calcium REAL DEFAULT 0,
        iron REAL DEFAULT 0,
        magnesium REAL DEFAULT 0,
        cholesterol REAL DEFAULT 0,
        is_default INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // Entries table with sync status
    await db.execute('''
      CREATE TABLE entries_local (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        food_id TEXT,
        date TEXT NOT NULL,
        meal TEXT NOT NULL,
        food_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        calories REAL DEFAULT 0,
        fat REAL DEFAULT 0,
        saturated_fat REAL DEFAULT 0,
        carbs REAL DEFAULT 0,
        fiber REAL DEFAULT 0,
        sugar REAL DEFAULT 0,
        protein REAL DEFAULT 0,
        sodium REAL DEFAULT 0,
        potassium REAL DEFAULT 0,
        calcium REAL DEFAULT 0,
        iron REAL DEFAULT 0,
        magnesium REAL DEFAULT 0,
        cholesterol REAL DEFAULT 0,
        created_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    // User targets cache
    await db.execute('''
      CREATE TABLE user_targets_cache (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        calories REAL DEFAULT 2100,
        fat REAL DEFAULT 70,
        saturated_fat REAL DEFAULT 20,
        carbs REAL DEFAULT 275,
        fiber REAL DEFAULT 34,
        sugar REAL DEFAULT 36,
        protein REAL DEFAULT 63,
        sodium REAL DEFAULT 2300,
        potassium REAL DEFAULT 3400,
        calcium REAL DEFAULT 1000,
        iron REAL DEFAULT 8,
        magnesium REAL DEFAULT 420,
        cholesterol REAL DEFAULT 300
      )
    ''');

    // Indexes
    await db.execute('CREATE INDEX idx_entries_date ON entries_local(date)');
    await db
        .execute('CREATE INDEX idx_entries_synced ON entries_local(is_synced)');
  }

  // ==================== FOODS CACHE ====================

  Future<void> cacheFoods(List<Food> foods) async {
    final db = await database;
    final batch = db.batch();

    // Clear existing cache
    batch.delete('foods_cache');

    // Insert new foods
    for (final food in foods) {
      batch.insert('foods_cache', {
        'id': food.id,
        'user_id': food.userId,
        'name': food.name,
        'unit': food.unit,
        'default_qty': food.defaultQty,
        'increment_by': food.incrementBy,
        'calories': food.calories,
        'fat': food.fat,
        'saturated_fat': food.saturatedFat,
        'carbs': food.carbs,
        'fiber': food.fiber,
        'sugar': food.sugar,
        'protein': food.protein,
        'sodium': food.sodium,
        'potassium': food.potassium,
        'calcium': food.calcium,
        'iron': food.iron,
        'magnesium': food.magnesium,
        'cholesterol': food.cholesterol,
        'is_default': food.isDefault ? 1 : 0,
        'created_at': food.createdAt?.toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }

  Future<List<Food>> getCachedFoods() async {
    final db = await database;
    final results = await db.query('foods_cache', orderBy: 'name');

    return results.map((json) {
      return Food(
        id: json['id'] as String?,
        userId: json['user_id'] as String?,
        name: json['name'] as String,
        unit: json['unit'] as String,
        defaultQty: (json['default_qty'] as num?)?.toDouble() ?? 1,
        incrementBy: (json['increment_by'] as num?)?.toDouble() ?? 1,
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        saturatedFat: (json['saturated_fat'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
        sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        sodium: (json['sodium'] as num?)?.toDouble() ?? 0,
        potassium: (json['potassium'] as num?)?.toDouble() ?? 0,
        calcium: (json['calcium'] as num?)?.toDouble() ?? 0,
        iron: (json['iron'] as num?)?.toDouble() ?? 0,
        magnesium: (json['magnesium'] as num?)?.toDouble() ?? 0,
        cholesterol: (json['cholesterol'] as num?)?.toDouble() ?? 0,
        isDefault: json['is_default'] == 1,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );
    }).toList();
  }

  // ==================== ENTRIES LOCAL ====================

  Future<void> saveEntryLocally(Entry entry, {bool isSynced = false}) async {
    final db = await database;
    await db.insert(
      'entries_local',
      {
        'id': entry.id,
        'user_id': entry.userId,
        'food_id': entry.foodId,
        'date': entry.date.toIso8601String().split('T')[0],
        'meal': entry.meal.name,
        'food_name': entry.foodName,
        'quantity': entry.quantity,
        'unit': entry.unit,
        'calories': entry.calories,
        'fat': entry.fat,
        'saturated_fat': entry.saturatedFat,
        'carbs': entry.carbs,
        'fiber': entry.fiber,
        'sugar': entry.sugar,
        'protein': entry.protein,
        'sodium': entry.sodium,
        'potassium': entry.potassium,
        'calcium': entry.calcium,
        'iron': entry.iron,
        'magnesium': entry.magnesium,
        'cholesterol': entry.cholesterol,
        'created_at': entry.createdAt?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Entry>> getLocalEntriesForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    final results = await db.query(
      'entries_local',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'created_at',
    );

    return results.map((json) => _entryFromLocalJson(json)).toList();
  }

  Future<List<Entry>> getLocalEntriesForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    final results = await db.query(
      'entries_local',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC, created_at',
    );

    return results.map((json) => _entryFromLocalJson(json)).toList();
  }

  Future<List<Entry>> getLocalEntriesForFood(String foodId) async {
    final db = await database;

    final results = await db.query(
      'entries_local',
      where: 'food_id = ?',
      whereArgs: [foodId],
      orderBy: 'date DESC, created_at',
    );

    return results.map((json) => _entryFromLocalJson(json)).toList();
  }

  Future<void> saveEntriesLocally(
    List<Entry> entries, {
    bool isSynced = false,
  }) async {
    for (final entry in entries) {
      await saveEntryLocally(entry, isSynced: isSynced);
    }
  }

  Future<List<Entry>> getUnsyncedEntries() async {
    final db = await database;
    final results = await db.query(
      'entries_local',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    return results.map((json) => _entryFromLocalJson(json)).toList();
  }

  Future<void> markEntrySynced(String id) async {
    final db = await database;
    await db.update(
      'entries_local',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteLocalEntry(String id) async {
    final db = await database;
    await db.delete(
      'entries_local',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearLocalEntriesForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    await db.delete(
      'entries_local',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
  }

  Entry _entryFromLocalJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      foodId: json['food_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      meal: MealExtension.fromString(json['meal'] as String),
      foodName: json['food_name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      saturatedFat: (json['saturated_fat'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0,
      potassium: (json['potassium'] as num?)?.toDouble() ?? 0,
      calcium: (json['calcium'] as num?)?.toDouble() ?? 0,
      iron: (json['iron'] as num?)?.toDouble() ?? 0,
      magnesium: (json['magnesium'] as num?)?.toDouble() ?? 0,
      cholesterol: (json['cholesterol'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isSynced: json['is_synced'] == 1,
    );
  }

  // ==================== USER TARGETS CACHE ====================

  Future<void> cacheUserTargets(UserTargets targets) async {
    final db = await database;
    await db.insert(
      'user_targets_cache',
      {
        'id': targets.id ?? 'default',
        'user_id': targets.userId,
        'calories': targets.calories,
        'fat': targets.fat,
        'saturated_fat': targets.saturatedFat,
        'carbs': targets.carbs,
        'fiber': targets.fiber,
        'sugar': targets.sugar,
        'protein': targets.protein,
        'sodium': targets.sodium,
        'potassium': targets.potassium,
        'calcium': targets.calcium,
        'iron': targets.iron,
        'magnesium': targets.magnesium,
        'cholesterol': targets.cholesterol,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserTargets?> getCachedUserTargets() async {
    final db = await database;
    final results = await db.query('user_targets_cache', limit: 1);

    if (results.isEmpty) return null;

    final json = results.first;
    return UserTargets(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      calories: (json['calories'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      saturatedFat: (json['saturated_fat'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      sugar: (json['sugar'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      sodium: (json['sodium'] as num).toDouble(),
      potassium: (json['potassium'] as num).toDouble(),
      calcium: (json['calcium'] as num).toDouble(),
      iron: (json['iron'] as num).toDouble(),
      magnesium: (json['magnesium'] as num).toDouble(),
      cholesterol: (json['cholesterol'] as num).toDouble(),
    );
  }

  // ==================== CLEANUP ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('foods_cache');
    await db.delete('entries_local');
    await db.delete('user_targets_cache');
  }
}
