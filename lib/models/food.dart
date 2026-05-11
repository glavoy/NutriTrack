class Food {
  final String? id;
  final String? userId;
  final String name;
  final String unit;
  final double defaultQty;
  final double incrementBy;
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
  final bool isDefault;
  final DateTime? createdAt;

  Food({
    this.id,
    this.userId,
    required this.name,
    required this.unit,
    this.defaultQty = 1,
    this.incrementBy = 1,
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
    this.isDefault = false,
    this.createdAt,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      defaultQty: (json['default_qty'] ?? 1).toDouble(),
      incrementBy: (json['increment_by'] ?? 1).toDouble(),
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
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'unit': unit,
      'default_qty': defaultQty,
      'increment_by': incrementBy,
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
      'is_default': isDefault,
    };
  }

  Food copyWith({
    String? id,
    String? userId,
    String? name,
    String? unit,
    double? defaultQty,
    double? incrementBy,
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
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Food(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      defaultQty: defaultQty ?? this.defaultQty,
      incrementBy: incrementBy ?? this.incrementBy,
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
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns a scaled version of this food's nutrients based on quantity
  Map<String, double> scaledNutrients(double quantity) {
    return {
      'calories': calories * quantity,
      'fat': fat * quantity,
      'saturatedFat': saturatedFat * quantity,
      'carbs': carbs * quantity,
      'fiber': fiber * quantity,
      'sugar': sugar * quantity,
      'protein': protein * quantity,
      'sodium': sodium * quantity,
      'potassium': potassium * quantity,
      'calcium': calcium * quantity,
      'iron': iron * quantity,
      'magnesium': magnesium * quantity,
      'cholesterol': cholesterol * quantity,
    };
  }
}
