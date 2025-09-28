import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/data/models/ingredient_model.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';

// A simple Cubit to manage the form's state directly in the UI file for simplicity.
class RecipeFormCubit extends Cubit<Recipe> {
  final RecipeRepository _recipeRepository;
  RecipeFormCubit(this._recipeRepository, Recipe? initialRecipe)
      : super(initialRecipe ??
      Recipe(
        name: '',
        servings: 1,
        cookTimeMinutes: 30,
        ingredients: [],
        instructions: [],
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

  void addIngredient() {
    final newIngredients = List<Ingredient>.from(state.ingredients)
      ..add(const Ingredient(quantity: 1, unit: 'pcs', name: ''));
    emit(Recipe(
      id: state.id, name: state.name, servings: state.servings, cookTimeMinutes: state.cookTimeMinutes,
      ingredients: newIngredients, // updated list
      instructions: state.instructions, tags: state.tags, imagePath: state.imagePath,
    ));
  }

  void updateIngredient(int index, Ingredient ingredient) {
    final newIngredients = List<Ingredient>.from(state.ingredients);
    newIngredients[index] = ingredient;
    emit(Recipe(
      id: state.id, name: state.name, servings: state.servings, cookTimeMinutes: state.cookTimeMinutes,
      ingredients: newIngredients, // updated list
      instructions: state.instructions, tags: state.tags, imagePath: state.imagePath,
    ));
  }

  void removeIngredient(int index) {
    final newIngredients = List<Ingredient>.from(state.ingredients)..removeAt(index);
    emit(Recipe(
      id: state.id, name: state.name, servings: state.servings, cookTimeMinutes: state.cookTimeMinutes,
      ingredients: newIngredients, // updated list
      instructions: state.instructions, tags: state.tags, imagePath: state.imagePath,
    ));
  }

  // Similar methods for instructions can be added here.

  Future<void> saveRecipe() async {
    await _recipeRepository.insertRecipe(state);
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
      child: BlocListener<RecipeFormCubit, Recipe>(
        listener: (context, state) {
          // Can show success/error snackbars here
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(recipe == null ? 'Add New Recipe' : 'Edit Recipe'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _RecipeForm(),
          ),
        ),
      ),
    );
  }
}

class _RecipeForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RecipeFormCubit>();
    final recipe = cubit.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: recipe.name,
          decoration: const InputDecoration(labelText: 'Recipe Name'),
          onChanged: (value) => cubit.updateField(name: value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: recipe.servings.toString(),
          decoration: const InputDecoration(labelText: 'Servings'),
          keyboardType: TextInputType.number,
          onChanged: (value) => cubit.updateField(servings: int.tryParse(value) ?? 1),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: recipe.cookTimeMinutes.toString(),
          decoration: const InputDecoration(labelText: 'Cook Time (minutes)'),
          keyboardType: TextInputType.number,
          onChanged: (value) => cubit.updateField(cookTimeMinutes: int.tryParse(value) ?? 0),
        ),
        const SizedBox(height: 24),
        Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recipe.ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = recipe.ingredients[index];
            return Row(
              children: [
                Expanded(child: TextFormField(initialValue: ingredient.quantity.toString())),
                const SizedBox(width: 8),
                Expanded(child: TextFormField(initialValue: ingredient.unit)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: TextFormField(initialValue: ingredient.name)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => cubit.removeIngredient(index),
                ),
              ],
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Ingredient'),
          onPressed: () => cubit.addIngredient(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          child: const Text('Save Recipe'),
          onPressed: () async {
            await context.read<RecipeFormCubit>().saveRecipe();
            if (context.mounted) {
              // Go back to the home screen
              context.go('/');
            }
          },
        ),
      ],
    );
  }
}