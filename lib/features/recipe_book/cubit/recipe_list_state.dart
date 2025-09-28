import 'package:equatable/equatable.dart';
import 'package:suvai/data/models/recipe_model.dart';

enum RecipeListStatus { initial, loading, success, failure }

class RecipeListState extends Equatable {
  final RecipeListStatus status;
  final List<Recipe> recipes;
  final String errorMessage;

  const RecipeListState({
    this.status = RecipeListStatus.initial,
    this.recipes = const [],
    this.errorMessage = '',
  });

  @override
  List<Object> get props => [status, recipes, errorMessage];

  RecipeListState copyWith({
    RecipeListStatus? status,
    List<Recipe>? recipes,
    String? errorMessage,
  }) {
    return RecipeListState(
      status: status ?? this.status,
      recipes: recipes ?? this.recipes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}