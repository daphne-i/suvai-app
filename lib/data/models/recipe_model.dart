import 'package:equatable/equatable.dart';
import 'ingredient_model.dart';

class Recipe extends Equatable {
  final int? id;
  final String name;
  final String? imagePath;
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

  @override
  List<Object?> get props => [id, name, imagePath, servings, cookTimeMinutes, ingredients, instructions, tags];
}