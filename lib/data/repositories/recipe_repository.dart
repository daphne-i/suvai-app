import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:suvai/core/database/database_service.dart';
import 'package:suvai/data/models/ingredient_model.dart';
import 'package:suvai/data/models/recipe_model.dart';

class RecipeRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Recipe>> getAllRecipes() async {
    final db = await _dbService.database;

    // 1. Fetch all recipe entries from the 'recipes' table.
    final List<Map<String, dynamic>> recipeMaps = await db.query('recipes');

    // 2. Iterate over each recipe map to fetch its associated ingredients.
    final List<Recipe> recipes = [];
    for (var recipeMap in recipeMaps) {
      final recipeId = recipeMap['id'] as int;

      // Fetch ingredients for the current recipe
      final List<Map<String, dynamic>> ingredientMaps = await db.query(
        'ingredients',
        where: 'recipeId = ?',
        whereArgs: [recipeId],
      );

      // Map the raw ingredient data to Ingredient models
      final ingredients = ingredientMaps.map((ingMap) {
        return Ingredient(
          id: ingMap['id'],
          recipeId: ingMap['recipeId'],
          name: ingMap['name'],
          quantity: ingMap['quantity'],
          unit: ingMap['unit'],
          preparation: ingMap['preparation'],
        );
      }).toList();

      // 3. Construct the final Recipe model
      recipes.add(
        Recipe(
          id: recipeId,
          name: recipeMap['name'],
          imagePath: recipeMap['imagePath'],
          servings: recipeMap['servings'],
          prepTimeMinutes: recipeMap['prepTimeMinutes'],
          cookTimeMinutes: recipeMap['cookTimeMinutes'],
          // Decode the JSON strings back into lists
          instructions: List<String>.from(jsonDecode(recipeMap['instructions'])),
          tags: List<String>.from(jsonDecode(recipeMap['tags'])),
          ingredients: ingredients,
        ),
      );
    }
    return recipes;
  }

  Future<void> insertRecipe(Recipe recipe) async {
    final db = await _dbService.database;

    // Use a transaction to ensure both operations succeed or fail together.
    await db.transaction((txn) async {
      // 1. Insert the recipe into the 'recipes' table.
      final recipeId = await txn.insert(
        'recipes',
        {
          'name': recipe.name,
          'imagePath': recipe.imagePath,
          'servings': recipe.servings,
          'prepTimeMinutes': recipe.prepTimeMinutes,
          'cookTimeMinutes': recipe.cookTimeMinutes,
          'instructions': jsonEncode(recipe.instructions),
          'tags': jsonEncode(recipe.tags),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Insert each ingredient into the 'ingredients' table.
      for (final ingredient in recipe.ingredients) {
        await txn.insert(
          'ingredients',
          {
            'recipeId': recipeId,
            'name': ingredient.name,
            'quantity': ingredient.quantity,
            'unit': ingredient.unit,
            'preparation': ingredient.preparation,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // 1. Update the main recipe entry
      await txn.update(
        'recipes',
        {
          'name': recipe.name,
          'imagePath': recipe.imagePath,
          'servings': recipe.servings,
          'prepTimeMinutes': recipe.prepTimeMinutes,
          'cookTimeMinutes': recipe.cookTimeMinutes,
          'instructions': jsonEncode(recipe.instructions),
          'tags': jsonEncode(recipe.tags),
        },
        where: 'id = ?',
        whereArgs: [recipe.id],
      );

      // 2. Delete all old ingredients associated with this recipe
      await txn.delete('ingredients', where: 'recipeId = ?', whereArgs: [recipe.id]);

      // 3. Insert the new list of ingredients
      for (final ingredient in recipe.ingredients) {
        await txn.insert('ingredients', {
          'recipeId': recipe.id,
          'name': ingredient.name,
          'quantity': ingredient.quantity,
          'unit': ingredient.unit,
          'preparation': ingredient.preparation,
        });
      }
    });
  }

  // --- ADD THIS NEW METHOD ---
  Future<void> deleteRecipe(int id) async {
    final db = await _dbService.database;
    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Note: The ON DELETE CASCADE constraint in our schema will automatically delete associated ingredients.
  }

  // This method is needed for the Recipe Detail Screen, but we won't implement that screen in this step.
  Future<Recipe?> getRecipeById(int id) async {
    // We will implement this in the next step when building the detail screen.
    return null;
  }
}
