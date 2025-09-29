import 'package:equatable/equatable.dart';
import 'package:suvai/data/models/meal_plan_model.dart';
import 'package:suvai/data/models/recipe_model.dart';

class MealPlannerState extends Equatable {
  // The start date of the week currently being displayed (always a Monday)
  final DateTime displayedWeekDate;
  // All meal plan entries for the displayed week
  final List<MealPlanEntry> mealPlanEntries;
  // A map of all recipes, for quick lookup by ID
  final Map<int, Recipe> recipeMap;

  const MealPlannerState({
    required this.displayedWeekDate,
    this.mealPlanEntries = const [],
    this.recipeMap = const {},
  });

  @override
  List<Object> get props => [displayedWeekDate, mealPlanEntries, recipeMap];

  MealPlannerState copyWith({
    DateTime? displayedWeekDate,
    List<MealPlanEntry>? mealPlanEntries,
    Map<int, Recipe>? recipeMap,
  }) {
    return MealPlannerState(
      displayedWeekDate: displayedWeekDate ?? this.displayedWeekDate,
      mealPlanEntries: mealPlanEntries ?? this.mealPlanEntries,
      recipeMap: recipeMap ?? this.recipeMap,
    );
  }
}