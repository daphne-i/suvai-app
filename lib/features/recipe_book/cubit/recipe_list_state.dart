import 'package:equatable/equatable.dart';
import 'package:suvai/data/models/recipe_model.dart';

enum RecipeListStatus { initial, loading, success, failure }

class RecipeListState extends Equatable {
  final RecipeListStatus status;
  final List<Recipe> recipes;
  final List<Recipe> filteredRecipes; // <-- ADD THIS
  final String? activeTagFilter;
  final String errorMessage;

  const RecipeListState({
    this.status = RecipeListStatus.initial,
    this.recipes = const [],
    this.filteredRecipes = const [], // <-- AND THIS
    this.activeTagFilter,
    this.errorMessage = '',
  });

  @override
  List<Object> get props => [status, recipes, filteredRecipes, ?activeTagFilter, errorMessage]; // <-- AND THIS

  RecipeListState copyWith({
    RecipeListStatus? status,
    List<Recipe>? recipes,
    List<Recipe>? filteredRecipes, // <-- AND THIS
    String? activeTagFilter,
    bool clearTagFilter = false,
    String? errorMessage,
  }) {
    return RecipeListState(
      status: status ?? this.status,
      recipes: recipes ?? this.recipes,
      filteredRecipes: filteredRecipes ?? this.filteredRecipes, // <-- AND THIS
      activeTagFilter: clearTagFilter ? null : activeTagFilter ?? this.activeTagFilter, // <-- ADD THIS
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}