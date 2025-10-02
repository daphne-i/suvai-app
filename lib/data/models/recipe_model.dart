// lib/data/models/recipe_model.dart

import 'package:equatable/equatable.dart';
import 'ingredient_model.dart';
import 'instruction_model.dart'; // Import the new model

class Recipe extends Equatable {
  final int? id;
  final String name;
  final String? imagePath;
  final int servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final List<Ingredient> ingredients;
  final List<Instruction> instructions; // Change this line
  final List<String> tags;

  const Recipe({
    this.id,
    required this.name,
    this.imagePath,
    required this.servings,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.ingredients,
    required this.instructions, // And this one
    required this.tags,
  });

  Recipe copyWith({
    int? id,
    String? name,
    String? imagePath,
    int? servings,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    List<Ingredient>? ingredients,
    List<Instruction>? instructions, // And this one
    List<String>? tags,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      servings: servings ?? this.servings,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions, // And this one
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    imagePath,
    servings,
    prepTimeMinutes,
    cookTimeMinutes,
    ingredients,
    instructions,
    tags
  ];
}