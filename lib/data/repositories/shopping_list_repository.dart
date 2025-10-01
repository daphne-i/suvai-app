import 'package:suvai/data/models/ingredient_model.dart';
import 'package:suvai/data/models/meal_plan_model.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/models/shopping_list_item_model.dart';
import 'package:suvai/data/repositories/meal_plan_repository.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';

class ShoppingListRepository {
  final MealPlanRepository _mealPlanRepo;
  final RecipeRepository _recipeRepo;

  ShoppingListRepository(this._mealPlanRepo, this._recipeRepo);

  Future<List<ShoppingListItem>> generateList(DateTime startDate) async {
    // 1. Fetch all meal plan entries for the week
    final mealPlan = await _mealPlanRepo.getMealPlansForWeek(startDate);

    // Fetch ALL recipes and put them in a map for easy and efficient lookup
    final allRecipesList = await _recipeRepo.getAllRecipes();
    final allRecipesMap = {for (var recipe in allRecipesList) recipe.id!: recipe};

    // 2. Consolidate ingredients by iterating through every planned meal
    final Map<String, ShoppingListItem> consolidatedItems = {};

    // Loop through each meal entry, NOT unique recipes
    for (var planEntry in mealPlan) {
      final recipe = allRecipesMap[planEntry.recipeId]; // Look up the recipe for this specific meal

      if (recipe != null) {
        // Now process the ingredients for this instance of the recipe
        for (var ingredient in recipe.ingredients) {
          final key = '${ingredient.name.trim().toLowerCase()}_${ingredient.unit.trim().toLowerCase()}';

          if (consolidatedItems.containsKey(key)) {
            // If the item already exists in our list, add the new quantity to the total
            final existingItem = consolidatedItems[key]!;
            final newQuantity = existingItem.quantity + ingredient.quantity;
            consolidatedItems[key] = ShoppingListItem(
                name: existingItem.name,
                unit: existingItem.unit,
                category: existingItem.category,
                quantity: newQuantity);
          } else {
            // If it's a new item, add it to our list for the first time
            consolidatedItems[key] = ShoppingListItem(
                name: ingredient.name.trim(),
                unit: ingredient.unit.trim(),
                category: _getCategoryForIngredient(ingredient.name),
                quantity: ingredient.quantity);
          }
        }
      }
    }

    // 3. Return the final list
    return consolidatedItems.values.toList();
  }

  // 3. Simple categorization logic
  String _getCategoryForIngredient(String name) {
    final n = name.toLowerCase();
    if (n.contains('onion') || n.contains('tomato') || n.contains('potato') || n.contains('ginger')) {
      return 'Produce';
    }
    if (n.contains('milk') || n.contains('cheese') || n.contains('yogurt') || n.contains('paneer')) {
      return 'Dairy & Cold';
    }
    if (n.contains('chicken') || n.contains('egg')) {
      return 'Meat & Poultry';
    }
    return 'Pantry';
  }
}