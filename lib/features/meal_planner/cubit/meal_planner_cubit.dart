import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suvai/data/repositories/meal_plan_repository.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'meal_planner_state.dart';
import 'package:suvai/data/models/meal_plan_model.dart'; // <-- Add this import
import 'package:suvai/data/models/recipe_model.dart'; // <-- Add this import

class MealPlannerCubit extends Cubit<MealPlannerState> {
  final MealPlanRepository _mealPlanRepository;
  final RecipeRepository _recipeRepository;

  MealPlannerCubit(this._mealPlanRepository, this._recipeRepository)
      : super(MealPlannerState(displayedWeekDate: _getMonday(DateTime.now()))) {
    loadMealPlanForWeek();
  }

  static DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> loadMealPlanForWeek() async {
    final entries = await _mealPlanRepository.getMealPlansForWeek(state.displayedWeekDate);
    final allRecipes = await _recipeRepository.getAllRecipes();
    final recipeMap = {for (var recipe in allRecipes) recipe.id!: recipe};

    emit(state.copyWith(mealPlanEntries: entries, recipeMap: recipeMap));
  }

  void goToNextWeek() {
    final nextWeek = state.displayedWeekDate.add(const Duration(days: 7));
    emit(state.copyWith(displayedWeekDate: nextWeek));
    loadMealPlanForWeek();
  }

  void goToPreviousWeek() {
    final previousWeek = state.displayedWeekDate.subtract(const Duration(days: 7));
    emit(state.copyWith(displayedWeekDate: previousWeek));
    loadMealPlanForWeek();
  }

  Future<void> addRecipeToPlan(Recipe recipe, DateTime date, MealType mealType) async {
    final newEntry = MealPlanEntry(
      date: date,
      mealType: mealType,
      recipeId: recipe.id!,
    );
    await _mealPlanRepository.addMealPlanEntry(newEntry);
    // Reload the data for the current week to show the new entry
    loadMealPlanForWeek();
  }

  Future<void> removeRecipeFromPlan(int mealPlanEntryId) async {
    await _mealPlanRepository.removeMealPlanEntry(mealPlanEntryId);
    // Reload the data for the current week to show the change
    loadMealPlanForWeek();
  }
}