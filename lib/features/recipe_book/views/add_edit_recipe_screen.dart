import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:suvai/data/models/ingredient_model.dart';
import 'package:suvai/data/models/instruction_model.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';

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
        instructions: [Instruction(description: '')],
        tags: [],
      ));

  void updateField(
      {String? name,
        int? servings,
        int? prepTimeMinutes,
        int? cookTimeMinutes}) {
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

  void updateIngredient(int index,
      {double? quantity, String? unit, String? name, String? prep}) {
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
    final newIngredients = List<Ingredient>.from(state.ingredients)
      ..removeAt(index);
    emit(state.copyWith(ingredients: newIngredients));
  }

  // --- INSTRUCTION METHODS ---
  void addInstruction() {
    final newInstructions = List<Instruction>.from(state.instructions)
      ..add(const Instruction(description: ''));
    emit(state.copyWith(instructions: newInstructions));
  }

  void updateInstruction(int index, String text, {int? duration}) {
    final newInstructions = List<Instruction>.from(state.instructions);
    newInstructions[index] = Instruction(
        description: text,
        durationInMinutes: duration ?? newInstructions[index].durationInMinutes);
    emit(state.copyWith(instructions: newInstructions));
  }

  void removeInstruction(int index) {
    final newInstructions = List<Instruction>.from(state.instructions)
      ..removeAt(index);
    emit(state.copyWith(instructions: newInstructions));
  }

  // --- TAGS METHOD ---
  void tagsChanged(String tagsString) {
    final tags = tagsString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    emit(state.copyWith(tags: tags));
  }

  Future<void> saveRecipe() async {
    final cleanRecipe = state.copyWith(
      ingredients:
      state.ingredients.where((i) => i.name.trim().isNotEmpty).toList(),
      instructions: state.instructions
          .where((i) => i.description.trim().isNotEmpty)
          .toList(),
    );

    if (cleanRecipe.id != null) {
      await _recipeRepository.updateRecipe(cleanRecipe);
    } else {
      await _recipeRepository.insertRecipe(cleanRecipe);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      // Get the app's document directory
      final appDir = await getApplicationDocumentsDirectory();
      // Generate a unique file name
      final fileName = path.basename(pickedFile.path);
      // Create a permanent path in the app's directory
      final savedImagePath = path.join(appDir.path, fileName);

      // Copy the picked image file to the permanent path
      final file = File(pickedFile.path);
      await file.copy(savedImagePath);

      // Update the state with the new image path
      emit(state.copyWith(imagePath: savedImagePath));
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
        body: const SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 40),
          child: _RecipeForm(),
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
          GestureDetector(
            onTap: () {
              // Show a dialog to choose between camera and gallery
              showModalBottomSheet(
                context: context,
                builder: (builderContext) {
                  return SafeArea(
                    child: Wrap(
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Photo Library'),
                          onTap: () {
                            cubit.pickImage(ImageSource.gallery);
                            Navigator.of(builderContext).pop();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_camera),
                          title: const Text('Camera'),
                          onTap: () {
                            cubit.pickImage(ImageSource.camera);
                            Navigator.of(builderContext).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              // Conditionally display the image or the placeholder
              child: recipe.imagePath != null && recipe.imagePath!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(recipe.imagePath!),
                  fit: BoxFit.cover,
                ),
              )
                  : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 40),
                    SizedBox(height: 8),
                    Text('Tap to add photo'),
                  ],
                ),
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
                  onChanged: (v) =>
                      cubit.updateField(servings: int.tryParse(v) ?? 1),
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoChipInput(
                  key: Key('prep_time_${recipe.id}'),
                  label: 'Prep Time (mins)',
                  initialValue: recipe.prepTimeMinutes.toString(),
                  onChanged: (v) =>
                      cubit.updateField(prepTimeMinutes: int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoChipInput(
                  key: Key('cook_time_${recipe.id}'),
                  label: 'Cook Time (mins)',
                  initialValue: recipe.cookTimeMinutes.toString(),
                  onChanged: (v) =>
                      cubit.updateField(cookTimeMinutes: int.tryParse(v) ?? 0),
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
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.red.shade400],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
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
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Colors.black87)),
    );
  }

  List<Widget> _buildIngredientsInputs(BuildContext context,
      List<Ingredient> ingredients, RecipeFormCubit cubit, int? recipeId) {
    return List.generate(ingredients.length, (index) {
      final ingredient = ingredients[index];
      final ingredientKey =
      Key('ingredient_${recipeId}_${ingredient.id ?? 'new_$index'}');
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
                      initialValue: ingredient.quantity > 0
                          ? ingredient.quantity.toString()
                          : '',
                      onChanged: (v) => cubit.updateIngredient(index,
                          quantity: double.tryParse(v)),
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
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

  List<Widget> _buildInstructionsInputs(BuildContext context,
      List<Instruction> instructions, RecipeFormCubit cubit, int? recipeId) {
    return List.generate(instructions.length, (index) {
      final instruction = instructions[index];
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
                initialValue: instruction.description,
                onChanged: (v) => cubit.updateInstruction(index, v),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: _StyledTextField(
                labelText: 'Time (mins)',
                initialValue: instruction.durationInMinutes?.toString() ?? '',
                onChanged: (v) => cubit.updateInstruction(
                    index, instruction.description,
                    duration: int.tryParse(v)),
                keyboardType: TextInputType.number,
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
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        color:
        isPrimary ? Colors.orange.shade800 : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 2),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
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