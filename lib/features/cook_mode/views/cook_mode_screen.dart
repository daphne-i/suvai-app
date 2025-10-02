import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/features/cook_mode/cubit/cook_mode_cubit.dart';
import 'package:suvai/features/cook_mode/cubit/cook_mode_state.dart';
import 'package:wakelock/wakelock.dart';

class CookModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookModeScreen({super.key, required this.recipe});

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  @override
  void initState() {
    super.initState();
    // Keep the screen from turning off
    Wakelock.enable();
  }

  @override
  void dispose() {
    // Allow the screen to turn off again
    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CookModeCubit(widget.recipe),
      child: BlocBuilder<CookModeCubit, CookModeState>(
        builder: (context, state) {
          final cubit = context.read<CookModeCubit>();
          final instruction = state.recipe.instructions[state.currentStep];
          final isFirstStep = state.currentStep == 0;
          final isLastStep = state.currentStep == state.recipe.instructions.length - 1;

          return Scaffold(
            appBar: AppBar(
              title: Text('Step ${state.currentStep + 1} of ${state.recipe.instructions.length}'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    onPressed: isFirstStep ? null : () => cubit.previousStep(),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    onPressed: isLastStep ? null : () => cubit.nextStep(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}