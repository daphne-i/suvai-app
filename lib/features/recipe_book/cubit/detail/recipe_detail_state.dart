import 'package:equatable/equatable.dart';
import 'package:suvai/data/models/recipe_model.dart';

enum RecipeDetailStatus { initial, loading, success, failure }

class RecipeDetailState extends Equatable {
  final RecipeDetailStatus status;
  final Recipe? recipe;
  final String errorMessage;

  const RecipeDetailState({
    this.status = RecipeDetailStatus.initial,
    this.recipe,
    this.errorMessage = '',
  });

  @override
  List<Object?> get props => [status, recipe, errorMessage];

  RecipeDetailState copyWith({
    RecipeDetailStatus? status,
    Recipe? recipe,
    String? errorMessage,
  }) {
    return RecipeDetailState(
      status: status ?? this.status,
      recipe: recipe ?? this.recipe,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}