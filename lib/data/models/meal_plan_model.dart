import 'package:equatable/equatable.dart';

enum MealType {
  breakfast,
  morningSnack, // <-- ADD THIS
  lunch,
  eveningSnack, // <-- ADD THIS
  dinner
}

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