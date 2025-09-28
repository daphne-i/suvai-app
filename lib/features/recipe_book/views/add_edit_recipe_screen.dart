import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/data/models/ingredient_model.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';

import '../cubit/recipe_list_cubit.dart';

// A simple Cubit to manage the form's state directly in the UI file for simplicity.
class RecipeFormCubit extends Cubit<Recipe> {
  final RecipeRepository _recipeRepository;
  RecipeFormCubit(this._recipeRepository, Recipe? initialRecipe)
      : super(initialRecipe ??
      Recipe(
        name: '',
        servings: 1,
        cookTimeMinutes: 30,
        ingredients: [Ingredient(quantity: 0, unit: '', name: '')], // Start with one empty ingredient
        instructions: [''], // Start with one empty instruction
        tags: [],
      ));

  void updateField({String? name, int? servings, int? cookTimeMinutes}) {
    emit(Recipe(
      id: state.id,
      name: name ?? state.name,
      servings: servings ?? state.servings,
      cookTimeMinutes: cookTimeMinutes ?? state.cookTimeMinutes,
      ingredients: state.ingredients,
      instructions: state.instructions,
      tags: state.tags,
      imagePath: state.imagePath,
    ));
  }

// --- INGREDIENT METHODS ---
  void addIngredient() {
    final newIngredients = List<Ingredient>.from(state.ingredients)
      ..add(const Ingredient(quantity: 0, unit: '', name: ''));
    emit(state.copyWith(ingredients: newIngredients));
  }

  void updateIngredient(int index, {double? quantity, String? unit, String? name, String? prep}) {
    final newIngredients = List<Ingredient>.from(state.ingredients);
    final old = newIngredients[index];
    newIngredients[index] = Ingredient(
        id: old.id,
        recipeId: old.recipeId,
        quantity: quantity ?? old.quantity,
        unit: unit ?? old.unit,
        name: name ?? old.name,
        preparation: prep ?? old.preparation);
    emit(state.copyWith(ingredients: newIngredients));
  }

  void removeIngredient(int index) {
    final newIngredients = List<Ingredient>.from(state.ingredients)..removeAt(index);
    emit(state.copyWith(ingredients: newIngredients));
  }

  // --- INSTRUCTION METHODS ---
  void addInstruction() {
    final newInstructions = List<String>.from(state.instructions)..add('');
    emit(state.copyWith(instructions: newInstructions));
  }

  void updateInstruction(int index, String text) {
    final newInstructions = List<String>.from(state.instructions);
    newInstructions[index] = text;
    emit(state.copyWith(instructions: newInstructions));
  }

  void removeInstruction(int index) {
    final newInstructions = List<String>.from(state.instructions)..removeAt(index);
    emit(state.copyWith(instructions: newInstructions));
  }


  Future<void> saveRecipe() async {
    // Filter out empty ingredients/instructions before saving
    final cleanRecipe = state.copyWith(
      ingredients: state.ingredients.where((i) => i.name.trim().isNotEmpty).toList(),
      instructions: state.instructions.where((i) => i.trim().isNotEmpty).toList(),
    );
    await _recipeRepository.insertRecipe(cleanRecipe);
  }
}

class AddEditRecipeScreen extends StatelessWidget {
  final RecipeRepository recipeRepository;
  final Recipe? recipe;

  const AddEditRecipeScreen({
    super.key,
    required this.recipeRepository,
    this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecipeFormCubit(recipeRepository, recipe),
      child: Scaffold(
        appBar: AppBar(
          title: Text(recipe == null ? 'Add New Recipe' : 'Edit Recipe'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        body: BlocBuilder<RecipeFormCubit, Recipe>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _RecipeForm(recipe: state),
            );
          },
        ),
      ),
    );
  }
}

class _RecipeForm extends StatelessWidget {
  final Recipe recipe;
  const _RecipeForm({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RecipeFormCubit>();

    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // We will add the image picker here later
          const SizedBox(height: 16),

          // --- Basic Info Section ---
          _buildSectionTitle(context, 'Basic Information'),
          _buildStyledTextFormField(
            initialValue: recipe.name,
            labelText: 'Recipe Name',
            onChanged: (value) => cubit.updateField(name: value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStyledTextFormField(
                  initialValue: recipe.servings.toString(),
                  labelText: 'Servings',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => cubit.updateField(servings: int.tryParse(value) ?? 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStyledTextFormField(
                  initialValue: recipe.cookTimeMinutes.toString(),
                  labelText: 'Cook Time (mins)',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => cubit.updateField(cookTimeMinutes: int.tryParse(value) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- Ingredients Section ---
          _buildSectionTitle(context, 'Ingredients'),
          ..._buildIngredientsInputs(context, recipe.ingredients, cubit),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Ingredient'),
            onPressed: () => cubit.addIngredient(),
          ),
          const SizedBox(height: 24),

          // --- Instructions Section ---
          _buildSectionTitle(context, 'Instructions'),
          ..._buildInstructionsInputs(context, recipe.instructions, cubit),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Instruction'),
            onPressed: () => cubit.addInstruction(),
          ),
          const SizedBox(height: 32),

          // --- Save Button ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              await cubit.saveRecipe();
              if (context.mounted) {
                context.pop();
              }
            },
            child: const Text('Save Recipe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  List<Widget> _buildIngredientsInputs(BuildContext context, List<Ingredient> ingredients, RecipeFormCubit cubit) {
    return List.generate(ingredients.length, (index) {
      final ingredient = ingredients[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildStyledTextFormField(
                      initialValue: ingredient.quantity != 0 ? ingredient.quantity.toString() : '',
                      labelText: 'Qty',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => cubit.updateIngredient(index, quantity: double.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStyledTextFormField(
                      initialValue: ingredient.unit,
                      labelText: 'Unit',
                      onChanged: (v) => cubit.updateIngredient(index, unit: v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => cubit.removeIngredient(index),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildStyledTextFormField(
                initialValue: ingredient.name,
                labelText: 'Ingredient Name',
                onChanged: (v) => cubit.updateIngredient(index, name: v),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildInstructionsInputs(BuildContext context, List<String> instructions, RecipeFormCubit cubit) {
    return List.generate(instructions.length, (index) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}.', style: const TextStyle(fontSize: 16, height: 2.5)),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStyledTextFormField(
                initialValue: instructions[index],
                labelText: 'Step ${index + 1}',
                maxLines: null, // Allows multiline
                onChanged: (v) => cubit.updateInstruction(index, v),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => cubit.removeInstruction(index),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStyledTextFormField({
    String? initialValue,
    String? labelText,
    void Function(String)? onChanged,
    TextInputType? keyboardType,
    int? maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}
