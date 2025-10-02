import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'cook_mode_state.dart';

class CookModeCubit extends Cubit<CookModeState> {
  CookModeCubit(Recipe recipe) : super(CookModeState(recipe: recipe));

  void nextStep() {
    if (state.currentStep < state.recipe.instructions.length - 1) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }
}