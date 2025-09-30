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
    // 1. Fetch data
    final mealPlan = await _mealPlanRepo.getMealPlansForWeek(startDate);
    final recipeIds = mealPlan.map((e) => e.recipeId).toSet();

    List<Recipe> recipes = [];
    for (var id in recipeIds) {
      final recipe = await _recipeRepo.getRecipeById(id);
      if (recipe != null) {
        recipes.add(recipe);
      }
    }

    // 2. Consolidate ingredients
    final Map<String, ShoppingListItem> consolidatedItems = {};
    for (var recipe in recipes) {
      for (var ingredient in recipe.ingredients) {
        final key = '${ingredient.name.trim().toLowerCase()}_${ingredient.unit.trim().toLowerCase()}';
        if (consolidatedItems.containsKey(key)) {
          final existing = consolidatedItems[key]!;
          consolidatedItems[key] = ShoppingListItem(
            name: existing.name,
            unit: existing.unit,
            category: existing.category,
            quantity: existing.quantity + ingredient.quantity,
          );
        } else {
          consolidatedItems[key] = ShoppingListItem(
            name: ingredient.name,
            unit: ingredient.unit,
            category: _getCategoryForIngredient(ingredient.name),
            quantity: ingredient.quantity,
          );
        }
      }
    }
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