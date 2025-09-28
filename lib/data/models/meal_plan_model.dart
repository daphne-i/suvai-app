import 'package:equatable/equatable.dart';

// Defines the meal slots for each day [cite: 49]
enum MealType { breakfast, lunch, dinner }

class MealPlanEntry extends Equatable {
  final int? id;
  final DateTime date;
  final MealType mealType;
  final int recipeId;

  const MealPlanEntry({
    this.id,
    required this.date,
    required this.mealType,
    required this.recipeId,
  });

  @override
  List<Object?> get props => [id, date, mealType, recipeId];
}