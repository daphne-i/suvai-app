import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:suvai/core/database/database_service.dart';
import 'package:suvai/data/models/ingredient_model.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/models/instruction_model.dart';

class RecipeRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Recipe>> getAllRecipes() async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> recipeMaps = await db.query('recipes');

    final List<Recipe> recipes = [];
    for (var recipeMap in recipeMaps) {
      final recipeId = recipeMap['id'] as int;

      final List<Map<String, dynamic>> ingredientMaps = await db.query(
        'ingredients',
        where: 'recipeId = ?',
        whereArgs: [recipeId],
      );

      final ingredients = ingredientMaps.map((ingMap) {
        return Ingredient.fromMap(ingMap);
      }).toList();

      // THIS IS THE CORRECTED LOGIC
      final dynamic decodedInstructions = jsonDecode(recipeMap['instructions']);
      final instructions = (decodedInstructions as List).map((i) {
        if (i is String) {
          // This handles the old data format (List<String>)
          return Instruction(description: i);
        } else {
          // This handles the new data format (List<Instruction>)
          return Instruction.fromJson(i);
        }
      }).toList();

      recipes.add(
        Recipe(
          id: recipeId,
          name: recipeMap['name'],
          imagePath: recipeMap['imagePath'],
          servings: recipeMap['servings'],
          prepTimeMinutes: recipeMap['prepTimeMinutes'],
          cookTimeMinutes: recipeMap['cookTimeMinutes'],
          instructions: instructions,
          tags: List<String>.from(jsonDecode(recipeMap['tags'])),
          ingredients: ingredients,
        ),
      );
    }
    return recipes;
  }

  Future<void> insertRecipe(Recipe recipe) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      final recipeId = await txn.insert(
        'recipes',
        {
          'name': recipe.name,
          'imagePath': recipe.imagePath,
          'servings': recipe.servings,
          'prepTimeMinutes': recipe.prepTimeMinutes,
          'cookTimeMinutes': recipe.cookTimeMinutes,
          'instructions': jsonEncode(recipe.instructions.map((i) => i.toJson()).toList()),
          'tags': jsonEncode(recipe.tags),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

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
      await txn.update(
        'recipes',
        {
          'name': recipe.name,
          'imagePath': recipe.imagePath,
          'servings': recipe.servings,
          'prepTimeMinutes': recipe.prepTimeMinutes,
          'cookTimeMinutes': recipe.cookTimeMinutes,
          'instructions': jsonEncode(recipe.instructions.map((i) => i.toJson()).toList()),
          'tags': jsonEncode(recipe.tags),
        },
        where: 'id = ?',
        whereArgs: [recipe.id],
      );

      await txn.delete('ingredients', where: 'recipeId = ?', whereArgs: [recipe.id]);

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

  Future<void> deleteRecipe(int id) async {
    final db = await _dbService.database;
    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Recipe?> getRecipeById(int id) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> recipeMaps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (recipeMaps.isEmpty) {
      return null;
    }

    final List<Map<String, dynamic>> ingredientMaps = await db.query(
      'ingredients',
      where: 'recipeId = ?',
      whereArgs: [id],
    );
    final ingredients = ingredientMaps.map((im) => Ingredient.fromMap(im)).toList();

    // THIS IS THE CORRECTED LOGIC
    final dynamic decodedInstructions = jsonDecode(recipeMaps.first['instructions']);
    final instructions = (decodedInstructions as List).map((i) {
      if (i is String) {
        // This handles the old data format (List<String>)
        return Instruction(description: i);
      } else {
        // This handles the new data format (List<Instruction>)
        return Instruction.fromJson(i);
      }
    }).toList();

    final recipeMap = recipeMaps.first;
    return Recipe(
      id: recipeMap['id'],
      name: recipeMap['name'],
      imagePath: recipeMap['imagePath'],
      servings: recipeMap['servings'],
      prepTimeMinutes: recipeMap['prepTimeMinutes'],
      cookTimeMinutes: recipeMap['cookTimeMinutes'],
      instructions: instructions,
      tags: (jsonDecode(recipeMap['tags']) as List<dynamic>).cast<String>(),
      ingredients: ingredients,
    );
  }
}