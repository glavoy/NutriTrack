enum Meal { breakfast, lunch, dinner, snack }

extension MealExtension on Meal {
  String get displayName {
    switch (this) {
      case Meal.breakfast:
        return 'Breakfast';
      case Meal.lunch:
        return 'Lunch';
      case Meal.dinner:
        return 'Dinner';
      case Meal.snack:
        return 'Snack';
    }
  }

  static Meal fromString(String value) {
    switch (value.toLowerCase()) {
      case 'breakfast':
        return Meal.breakfast;
      case 'lunch':
        return Meal.lunch;
      case 'dinner':
        return Meal.dinner;
      case 'snack':
        return Meal.snack;
      default:
        return Meal.snack;
    }
  }
}

class Entry {
  final String? id;
  final String? userId;
  final String? foodId;
  final DateTime date;
  final Meal meal;
  final String foodName;
  final double quantity;
  final String unit;
  final double calories;
  final double fat;
  final double saturatedFat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double protein;
  final double sodium;
  final double potassium;
  final double calcium;
  final double iron;
  final double magnesium;
  final double cholesterol;
  final DateTime? createdAt;
  final bool isSynced;

  Entry({
    this.id,
    this.userId,
    this.foodId,
    required this.date,
    required this.meal,
    required this.foodName,
    required this.quantity,
    required this.unit,
    this.calories = 0,
    this.fat = 0,
    this.saturatedFat = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.protein = 0,
    this.sodium = 0,
    this.potassium = 0,
    this.calcium = 0,
    this.iron = 0,
    this.magnesium = 0,
    this.cholesterol = 0,
    this.createdAt,
    this.isSynced = true,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'],
      userId: json['user_id'],
      foodId: json['food_id'],
      date: DateTime.parse(json['date']),
      meal: MealExtension.fromString(json['meal'] ?? 'snack'),
      foodName: json['food_name'] ?? '',
      quantity: (json['quantity'] ?? 1).toDouble(),
      unit: json['unit'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      saturatedFat: (json['saturated_fat'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sugar: (json['sugar'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      potassium: (json['potassium'] ?? 0).toDouble(),
      calcium: (json['calcium'] ?? 0).toDouble(),
      iron: (json['iron'] ?? 0).toDouble(),
      magnesium: (json['magnesium'] ?? 0).toDouble(),
      cholesterol: (json['cholesterol'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      isSynced: json['is_synced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (foodId != null) 'food_id': foodId,
      'date': date.toIso8601String().split('T')[0],
      'meal': meal.name,
      'food_name': foodName,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'fat': fat,
      'saturated_fat': saturatedFat,
      'carbs': carbs,
      'fiber': fiber,
      'sugar': sugar,
      'protein': protein,
      'sodium': sodium,
      'potassium': potassium,
      'calcium': calcium,
      'iron': iron,
      'magnesium': magnesium,
      'cholesterol': cholesterol,
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      ...toJson(),
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Entry copyWith({
    String? id,
    String? userId,
    String? foodId,
    DateTime? date,
    Meal? meal,
    String? foodName,
    double? quantity,
    String? unit,
    double? calories,
    double? fat,
    double? saturatedFat,
    double? carbs,
    double? fiber,
    double? sugar,
    double? protein,
    double? sodium,
    double? potassium,
    double? calcium,
    double? iron,
    double? magnesium,
    double? cholesterol,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return Entry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodId: foodId ?? this.foodId,
      date: date ?? this.date,
      meal: meal ?? this.meal,
      foodName: foodName ?? this.foodName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      fat: fat ?? this.fat,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      protein: protein ?? this.protein,
      sodium: sodium ?? this.sodium,
      potassium: potassium ?? this.potassium,
      calcium: calcium ?? this.calcium,
      iron: iron ?? this.iron,
      magnesium: magnesium ?? this.magnesium,
      cholesterol: cholesterol ?? this.cholesterol,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

class DailyTotals {
  final double calories;
  final double fat;
  final double saturatedFat;
  final double carbs;
  final double fiber;
  final double sugar;
  final double protein;
  final double sodium;
  final double potassium;
  final double calcium;
  final double iron;
  final double magnesium;
  final double cholesterol;

  DailyTotals({
    this.calories = 0,
    this.fat = 0,
    this.saturatedFat = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.protein = 0,
    this.sodium = 0,
    this.potassium = 0,
    this.calcium = 0,
    this.iron = 0,
    this.magnesium = 0,
    this.cholesterol = 0,
  });

  factory DailyTotals.fromEntries(List<Entry> entries) {
    return DailyTotals(
      calories: entries.fold(0, (sum, e) => sum + e.calories),
      fat: entries.fold(0, (sum, e) => sum + e.fat),
      saturatedFat: entries.fold(0, (sum, e) => sum + e.saturatedFat),
      carbs: entries.fold(0, (sum, e) => sum + e.carbs),
      fiber: entries.fold(0, (sum, e) => sum + e.fiber),
      sugar: entries.fold(0, (sum, e) => sum + e.sugar),
      protein: entries.fold(0, (sum, e) => sum + e.protein),
      sodium: entries.fold(0, (sum, e) => sum + e.sodium),
      potassium: entries.fold(0, (sum, e) => sum + e.potassium),
      calcium: entries.fold(0, (sum, e) => sum + e.calcium),
      iron: entries.fold(0, (sum, e) => sum + e.iron),
      magnesium: entries.fold(0, (sum, e) => sum + e.magnesium),
      cholesterol: entries.fold(0, (sum, e) => sum + e.cholesterol),
    );
  }
}
