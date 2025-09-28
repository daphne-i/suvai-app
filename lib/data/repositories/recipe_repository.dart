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

// We will add insert, update, and delete methods here in later steps.
}