import 'package:equatable/equatable.dart';
import 'ingredient_model.dart';

class Recipe extends Equatable {
  final int? id;
  final String name;
  final String? imagePath;
  final int servings;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final List<String> tags;

  const Recipe({
    this.id,
    required this.name,
    this.imagePath,
    required this.servings,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.ingredients,
    required this.instructions,
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
    List<String>? instructions,
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
    prepTimeMinutes,
    cookTimeMinutes,
    ingredients,
    instructions,
    tags
  ];
}