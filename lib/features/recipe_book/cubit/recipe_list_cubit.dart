import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'recipe_list_state.dart';

class RecipeListCubit extends Cubit<RecipeListState> {
  final RecipeRepository _recipeRepository;
  String _currentSearchQuery = '';

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

  void filterByTag(String tag) {
    emit(state.copyWith(activeTagFilter: tag));
    _applyFilters(); // Apply all filters together
  }

  void clearTagFilter() {
    emit(state.copyWith(clearTagFilter: true));
    _applyFilters();
  }

  void searchQueryChanged(String query) {
    _currentSearchQuery = query;
    _applyFilters();
  }

  // --- NEW PRIVATE HELPER METHOD ---
  void _applyFilters() {
    List<Recipe> filtered = List.from(state.recipes);

    // 1. Apply tag filter first
    if (state.activeTagFilter != null) {
      filtered = filtered.where((recipe) {
        return recipe.tags.any((tag) => tag.toLowerCase() == state.activeTagFilter!.toLowerCase());
      }).toList();
    }

    // 2. Apply search query on the result of the tag filter
    if (_currentSearchQuery.isNotEmpty) {
      filtered = filtered.where((recipe) {
        final queryLower = _currentSearchQuery.toLowerCase();
        final nameMatch = recipe.name.toLowerCase().contains(queryLower);
        final tagMatch = recipe.tags.any((tag) => tag.toLowerCase().contains(queryLower));
        return nameMatch || tagMatch;
      }).toList();
    }

    emit(state.copyWith(filteredRecipes: filtered));
  }

  Future<void> deleteRecipe(int id) async {
    try {
      await _recipeRepository.deleteRecipe(id);
      // After deleting, reload the list to reflect the change
      loadRecipes();
    } catch (e) {
      // Handle potential errors
      emit(state.copyWith(status: RecipeListStatus.failure, errorMessage: e.toString()));
    }
  }
}