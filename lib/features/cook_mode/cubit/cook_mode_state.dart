import 'package:equatable/equatable.dart';
import 'package:suvai/data/models/recipe_model.dart';

class CookModeState extends Equatable {
  final Recipe recipe;
  final int currentStep;

  const CookModeState({
    required this.recipe,
    this.currentStep = 0,
  });

  @override
  List<Object> get props => [recipe, currentStep];

  CookModeState copyWith({
    int? currentStep,
  }) {
    return CookModeState(
      recipe: recipe,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}