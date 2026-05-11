class UserTargets {
  final String? id;
  final String? userId;
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

  UserTargets({
    this.id,
    this.userId,
    this.calories = 2100,
    this.fat = 70,
    this.saturatedFat = 20,
    this.carbs = 275,
    this.fiber = 34,
    this.sugar = 36,
    this.protein = 63,
    this.sodium = 2300,
    this.potassium = 3400,
    this.calcium = 1000,
    this.iron = 8,
    this.magnesium = 420,
    this.cholesterol = 300,
  });

  factory UserTargets.fromJson(Map<String, dynamic> json) {
    return UserTargets(
      id: json['id'],
      userId: json['user_id'],
      calories: (json['calories'] ?? 2100).toDouble(),
      fat: (json['fat'] ?? 70).toDouble(),
      saturatedFat: (json['saturated_fat'] ?? 20).toDouble(),
      carbs: (json['carbs'] ?? 275).toDouble(),
      fiber: (json['fiber'] ?? 34).toDouble(),
      sugar: (json['sugar'] ?? 36).toDouble(),
      protein: (json['protein'] ?? 63).toDouble(),
      sodium: (json['sodium'] ?? 2300).toDouble(),
      potassium: (json['potassium'] ?? 3400).toDouble(),
      calcium: (json['calcium'] ?? 1000).toDouble(),
      iron: (json['iron'] ?? 8).toDouble(),
      magnesium: (json['magnesium'] ?? 420).toDouble(),
      cholesterol: (json['cholesterol'] ?? 300).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
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

  UserTargets copyWith({
    String? id,
    String? userId,
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
  }) {
    return UserTargets(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
    );
  }

  /// Returns default targets for a 56yo male at 70kg
  static UserTargets defaultTargets() => UserTargets();

  double getTarget(String nutrient) {
    switch (nutrient) {
      case 'calories':
        return calories;
      case 'fat':
        return fat;
      case 'saturatedFat':
        return saturatedFat;
      case 'carbs':
        return carbs;
      case 'fiber':
        return fiber;
      case 'sugar':
        return sugar;
      case 'protein':
        return protein;
      case 'sodium':
        return sodium;
      case 'potassium':
        return potassium;
      case 'calcium':
        return calcium;
      case 'iron':
        return iron;
      case 'magnesium':
        return magnesium;
      case 'cholesterol':
        return cholesterol;
      default:
        return 0;
    }
  }
}
