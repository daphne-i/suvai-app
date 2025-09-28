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
      // Initially, the filtered list is the same as the full list
      emit(state.copyWith(
        status: RecipeListStatus.success,
        recipes: recipes,
        filteredRecipes: recipes,
      ));
    } catch (e) {
      emit(state.copyWith(status: RecipeListStatus.failure, errorMessage: e.toString()));
    }
  }

  // --- ADD THIS NEW METHOD ---
  void searchQueryChanged(String query) {
    if (query.isEmpty) {
      // If the query is empty, show all recipes
      emit(state.copyWith(filteredRecipes: state.recipes));
    } else {
      // Otherwise, filter the master list of recipes
      final filtered = state.recipes.where((recipe) {
        final queryLower = query.toLowerCase();
        final nameMatch = recipe.name.toLowerCase().contains(queryLower);
        // We can also search by tags as per the user story [cite: 36, 41]
        final tagMatch = recipe.tags.any((tag) => tag.toLowerCase().contains(queryLower));
        return nameMatch || tagMatch;
      }).toList();
      emit(state.copyWith(filteredRecipes: filtered));
    }
  }
}