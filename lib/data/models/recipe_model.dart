import 'package:equatable/equatable.dart';
import 'ingredient_model.dart';

class Recipe extends Equatable {
  final int? id;
  final String name;
  final String? imagePath; // Local file path
  final int servings;
  final int cookTimeMinutes;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final List<String> tags;

  const Recipe({
    this.id,
    required this.name,
    this.imagePath,
    required this.servings,
    required this.cookTimeMinutes,
    required this.ingredients,
    required this.instructions,
    required this.tags,
  });

  // --- ADD THIS ENTIRE METHOD ---
  Recipe copyWith({
    int? id,
    String? name,
    String? imagePath,
    int? servings,
    int? cookTimeMinutes,
    List<Ingredient>? ingredients,
    List<String>? instructions,
    List<String>? tags,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      servings: servings ?? this.servings,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    imagePath,
    servings,
    cookTimeMinutes,
    ingredients,
    instructions,
    tags
  ];
}