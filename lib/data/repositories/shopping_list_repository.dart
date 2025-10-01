import 'package:suvai/data/models/ingredient_model.dart';
import 'package:suvai/data/models/meal_plan_model.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/models/shopping_list_item_model.dart';
import 'package:suvai/data/repositories/meal_plan_repository.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListRepository {
  final MealPlanRepository _mealPlanRepo;
  final RecipeRepository _recipeRepo;

  ShoppingListRepository(this._mealPlanRepo, this._recipeRepo);

  Future<List<ShoppingListItem>> generateList(DateTime startDate) async {
    // Get an instance of shared preferences
    final prefs = await SharedPreferences.getInstance();

    // (The logic to fetch meal plans and recipes is the same)
    final mealPlan = await _mealPlanRepo.getMealPlansForWeek(startDate);
    final allRecipesList = await _recipeRepo.getAllRecipes();
    final allRecipesMap = {for (var recipe in allRecipesList) recipe.id!: recipe};

    final Map<String, ShoppingListItem> consolidatedItems = {};
    for (var planEntry in mealPlan) {
      final recipe = allRecipesMap[planEntry.recipeId];
      if (recipe != null) {
        for (var ingredient in recipe.ingredients) {
          final key = '${ingredient.name.trim().toLowerCase()}_${ingredient.unit.trim().toLowerCase()}';
          final isChecked = prefs.getBool(key) ?? false; // <-- 3. Load the saved status

          if (consolidatedItems.containsKey(key)) {
            final existingItem = consolidatedItems[key]!;
            final newQuantity = existingItem.quantity + ingredient.quantity;
            consolidatedItems[key] = ShoppingListItem(
              name: existingItem.name,
              unit: existingItem.unit,
              category: existingItem.category,
              quantity: newQuantity,
              isChecked: isChecked, // <-- 4. Apply the loaded status
            );
          } else {
            consolidatedItems[key] = ShoppingListItem(
              name: ingredient.name.trim(),
              unit: ingredient.unit.trim(),
              category: _getCategoryForIngredient(ingredient.name),
              quantity: ingredient.quantity,
              isChecked: isChecked, // <-- 4. Apply the loaded status
            );
          }
        }
      }
    }
    return consolidatedItems.values.toList();
  }
}

  // 3. Simple categorization logic
  String _getCategoryForIngredient(String name) {
    final n = name.toLowerCase();
    if (n.contains('onion') || n.contains('tomato') || n.contains('potato') || n.contains('ginger')
        || n.contains('palak') || n.contains('garlic') || n.contains('chilli') || n.contains('green chilli')
        || n.contains('carrot') || n.contains('beans') || n.contains('beetroot') || n.contains('yam')
        || n.contains('cabbage') || n.contains('cauliflower') || n.contains('bitter gourd')
        || n.contains('cucumber') || n.contains('lemon')) {
      return 'Produce';
    }
    if (n.contains('milk') || n.contains('cheese') || n.contains('curd') || n.contains('paneer')) {
      return 'Dairy & Cold';
    }
    if (n.contains('chicken') || n.contains('egg') || n.contains('beef') || n.contains('mutton')) {
      return 'Meat & Poultry';
    }
    return 'Pantry';
  }
