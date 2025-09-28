import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'recipe_list_state.dart';

class RecipeListCubit extends Cubit<RecipeListState> {
  final RecipeRepository _recipeRepository;

  RecipeListCubit(this._recipeRepository) : super(const RecipeListState());

  Future<void> loadRecipes() async {
    emit(state.copyWith(status: RecipeListStatus.loading));
    try {
      final recipes = await _recipeRepository.getAllRecipes();
      emit(state.copyWith(status: RecipeListStatus.success, recipes: recipes));
    } catch (e) {
      emit(state.copyWith(status: RecipeListStatus.failure, errorMessage: e.toString()));
    }
  }
}