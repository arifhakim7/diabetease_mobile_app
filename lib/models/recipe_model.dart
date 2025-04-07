class Recipe {
  final int recipeID;
  final String recipeName;
  final String description;
  final List<Ingredient> ingredients;
  final List<String> preparationSteps;
  final int authorID;
  final DateTime uploadDate;
  final String? image;
  final NutritionalContent nutritionalContent;

  Recipe({
    required this.recipeID,
    required this.recipeName,
    required this.description,
    required this.ingredients,
    required this.preparationSteps,
    required this.authorID,
    required this.uploadDate,
    this.image,
    required this.nutritionalContent,
  });
}

class Ingredient {
  final String name;
  final double quantity;

  Ingredient({required this.name, required this.quantity});
}

class NutritionalContent {
  final int totalCalories;
  final double totalFat;
  final double saturatedFat;
  final double transFat;
  final double cholesterol;
  final double sodium;
  final double totalCarbohydrates;
  final double dietaryFiber;
  final double sugars;
  final double protein;
  final double? glycemicIndex;
  final int? giScore;

  NutritionalContent({
    required this.totalCalories,
    required this.totalFat,
    required this.saturatedFat,
    required this.transFat,
    required this.cholesterol,
    required this.sodium,
    required this.totalCarbohydrates,
    required this.dietaryFiber,
    required this.sugars,
    required this.protein,
    this.glycemicIndex,
    this.giScore,
  });
}
