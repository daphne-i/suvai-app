import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'recipe_detail_state.dart';

class RecipeDetailCubit extends Cubit<RecipeDetailState> {
  final RecipeRepository _recipeRepository;

  RecipeDetailCubit(this._recipeRepository) : super(const RecipeDetailState());

  Future<void> loadRecipe(int id) async {
    emit(state.copyWith(status: RecipeDetailStatus.loading));
    try {
      final recipe = await _recipeRepository.getRecipeById(id);
      if (recipe != null) {
        emit(state.copyWith(status: RecipeDetailStatus.success, recipe: recipe));
      } else {
        emit(state.copyWith(status: RecipeDetailStatus.failure, errorMessage: 'Recipe not found.'));
      }
    } catch (e) {
      emit(state.copyWith(status: RecipeDetailStatus.failure, errorMessage: e.toString()));
    }
  }
}