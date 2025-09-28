import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/data/models/ingredient_model.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/features/recipe_book/cubit/recipe_list_cubit.dart';

// The Cubit to manage the state of the recipe form
class RecipeFormCubit extends Cubit<Recipe> {
  final RecipeRepository _recipeRepository;

  RecipeFormCubit(this._recipeRepository, Recipe? initialRecipe)
      : super(initialRecipe ??
      const Recipe(
        name: '',
        servings: 1,
        prepTimeMinutes: 15,
        cookTimeMinutes: 30,
        ingredients: [Ingredient(quantity: 0, unit: 'g', name: '')],
        instructions: [''],
        tags: [],
      ));

  void updateField({String? name, int? servings, int? prepTimeMinutes, int? cookTimeMinutes}) {
    emit(state.copyWith(
      name: name,
      servings: servings,
      prepTimeMinutes: prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes,
    ));
  }

  // --- INGREDIENT METHODS ---
  void addIngredient() {
    final newIngredients = List<Ingredient>.from(state.ingredients)
      ..add(const Ingredient(quantity: 0, unit: 'g', name: ''));
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

  // --- TAGS METHOD ---
  void tagsChanged(String tagsString) {
    final tags = tagsString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    emit(state.copyWith(tags: tags));
  }

  Future<void> saveRecipe() async {
    final cleanRecipe = state.copyWith(
      ingredients: state.ingredients.where((i) => i.name.trim().isNotEmpty).toList(),
      instructions: state.instructions.where((i) => i.trim().isNotEmpty).toList(),
    );

    if (cleanRecipe.id != null) {
      await _recipeRepository.updateRecipe(cleanRecipe);
    } else {
      await _recipeRepository.insertRecipe(cleanRecipe);
    }
  }
}

// --- MAIN SCREEN WIDGET ---
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          child: const _RecipeForm(),
        ),
      ),
    );
  }
}

// --- FORM WIDGET ---
class _RecipeForm extends StatelessWidget {
  const _RecipeForm();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RecipeFormCubit>();
    final recipe = cubit.state;
    final formKey = Key('recipe_form_${recipe.id ?? 'new'}');

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.white54),
                  SizedBox(height: 8),
                  Text('Tap to add photo', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _InfoChipInput(
                  key: Key('servings_${recipe.id}'),
                  label: 'Servings',
                  initialValue: recipe.servings.toString(),
                  onChanged: (v) => cubit.updateField(servings: int.tryParse(v) ?? 1),
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoChipInput(
                  key: Key('prep_time_${recipe.id}'),
                  label: 'Prep Time (mins)',
                  initialValue: recipe.prepTimeMinutes.toString(), // <-- FIX THIS
                  onChanged: (v) => cubit.updateField(prepTimeMinutes: int.tryParse(v) ?? 0), // <-- FIX THIS
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoChipInput(
                  key: Key('cook_time_${recipe.id}'),
                  label: 'Cook Time (mins)',
                  initialValue: recipe.cookTimeMinutes.toString(),
                  onChanged: (v) => cubit.updateField(cookTimeMinutes: int.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StyledTextField(
            key: Key('name_${recipe.id}'),
            hintText: 'Recipe Name',
            initialValue: recipe.name,
            onChanged: (value) => cubit.updateField(name: value),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _StyledTextField(
            key: Key('tags_${recipe.id}'),
            hintText: 'Tags (e.g., Breakfast, Spicy, Vegetarian)',
            initialValue: recipe.tags.join(', '),
            onChanged: (value) => cubit.tagsChanged(value),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Ingredients'),
          ..._buildIngredientsInputs(context, recipe.ingredients, cubit, recipe.id),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add more ingredients'),
            onPressed: () => cubit.addIngredient(),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Instructions'),
          ..._buildInstructionsInputs(context, recipe.instructions, cubit, recipe.id),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add new step'),
            onPressed: () => cubit.addInstruction(),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.red.shade600],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              onPressed: () async {
                await cubit.saveRecipe();
                if (context.mounted) {
                  context.pop();
                }
              },
              child: const Text(
                'Save Recipe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
    );
  }

  List<Widget> _buildIngredientsInputs(BuildContext context, List<Ingredient> ingredients, RecipeFormCubit cubit, int? recipeId) {
    return List.generate(ingredients.length, (index) {
      final ingredient = ingredients[index];
      final ingredientKey = Key('ingredient_${recipeId}_${ingredient.id ?? index}');
      return Card(
        key: ingredientKey,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _StyledTextField(
                      hintText: 'Ingredient Name',
                      initialValue: ingredient.name,
                      onChanged: (v) => cubit.updateIngredient(index, name: v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: _StyledTextField(
                      hintText: 'Qty',
                      initialValue: ingredient.quantity > 0 ? ingredient.quantity.toString() : '',
                      onChanged: (v) => cubit.updateIngredient(index, quantity: double.tryParse(v)),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _StyledTextField(
                      hintText: 'Preparation (e.g., finely chopped)',
                      initialValue: ingredient.preparation,
                      onChanged: (v) => cubit.updateIngredient(index, prep: v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: ingredient.unit,
                      items: const [
                        'cup', 'g', 'inch', 'Kg', 'm', 'mL', 'no', 'packet', 'pcs', 'tbsp', 'tsp'
                      ].map((String unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          cubit.updateIngredient(index, unit: newValue);
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => cubit.removeIngredient(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildInstructionsInputs(BuildContext context, List<String> instructions, RecipeFormCubit cubit, int? recipeId) {
    return List.generate(instructions.length, (index) {
      final instructionKey = Key('instruction_${recipeId}_$index');
      return Padding(
        key: instructionKey,
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StyledTextField(
                labelText: 'Step ${index + 1}',
                initialValue: instructions[index],
                onChanged: (v) => cubit.updateInstruction(index, v),
                maxLines: null,
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
}

// --- REUSABLE WIDGETS FOR STYLING ---
class _StyledTextField extends StatelessWidget {
  final String? initialValue;
  final String? hintText;
  final String? labelText;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;
  final TextStyle? style;

  const _StyledTextField({
    super.key,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      style: style,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}

class _InfoChipInput extends StatelessWidget {
  final String label;
  final String initialValue;
  final void Function(String) onChanged;
  final bool isPrimary;

  const _InfoChipInput({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.orange.shade800 : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 2),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}