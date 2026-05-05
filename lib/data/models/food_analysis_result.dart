class FoodAnalysisResult {
  const FoodAnalysisResult({
    required this.foodName,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.description,
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisResult(
      foodName: json['foodName'] as String? ?? '분석된 음식',
      calories: _toInt(json['calories']),
      carbs: _toInt(json['carbs']),
      protein: _toInt(json['protein']),
      fat: _toInt(json['fat']),
      description: json['description'] as String? ?? '',
    );
  }

  final String foodName;
  final int calories;
  final int carbs;
  final int protein;
  final int fat;
  final String description;

  Map<String, Object?> toJson() {
    return {
      'foodName': foodName,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'description': description,
    };
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return double.tryParse(value)?.round() ?? 0;
    }
    return 0;
  }
}
