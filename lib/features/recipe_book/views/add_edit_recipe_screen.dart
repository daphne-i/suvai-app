import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:suvai/data/models/ingredient_model.dart';
import 'package:suvai/data/models/instruction_model.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';

// --- STATE CLASS TO HOLD FORM DATA AND SUGGESTIONS ---
class RecipeFormState {
  final Recipe recipe;
  final List<String> tagSuggestions;
  final List<String> ingredientSuggestions;

  const RecipeFormState({
    required this.recipe,
    this.tagSuggestions = const [],
    this.ingredientSuggestions = const [],
  });

  RecipeFormState copyWith({
    Recipe? recipe,
    List<String>? tagSuggestions,
    List<String>? ingredientSuggestions,
  }) {
    return RecipeFormState(
      recipe: recipe ?? this.recipe,
      tagSuggestions: tagSuggestions ?? this.tagSuggestions,
      ingredientSuggestions:
      ingredientSuggestions ?? this.ingredientSuggestions,
    );
  }
}

// --- UPDATED CUBIT ---
class RecipeFormCubit extends Cubit<RecipeFormState> {
  final RecipeRepository _recipeRepository;

  RecipeFormCubit(this._recipeRepository, Recipe? initialRecipe)
      : super(RecipeFormState(
    recipe: initialRecipe ??
        const Recipe(
          name: '',
          servings: 1,
          prepTimeMinutes: 15,
          cookTimeMinutes: 30,
          ingredients: [Ingredient(quantity: 0, unit: 'g', name: '')],
          instructions: [Instruction(description: '')],
          tags: [],
        ),
  )) {
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final tags = await _recipeRepository.getAllTags();
    final ingredients = await _recipeRepository.getAllIngredientNames();
    emit(state.copyWith(
      tagSuggestions: tags,
      ingredientSuggestions: ingredients,
    ));
  }

  void updateField(
      {String? name,
        int? servings,
        int? prepTimeMinutes,
        int? cookTimeMinutes}) {
    emit(state.copyWith(
        recipe: state.recipe.copyWith(
          name: name,
          servings: servings,
          prepTimeMinutes: prepTimeMinutes,
          cookTimeMinutes: cookTimeMinutes,
        )));
  }

  // --- INGREDIENT METHODS ---
  void addIngredient() {
    final newIngredients = List<Ingredient>.from(state.recipe.ingredients)
      ..add(const Ingredient(quantity: 0, unit: 'g', name: ''));
    emit(state.copyWith(recipe: state.recipe.copyWith(ingredients: newIngredients)));
  }

  void updateIngredient(int index,
      {double? quantity, String? unit, String? name, String? prep}) {
    final newIngredients = List<Ingredient>.from(state.recipe.ingredients);
    final old = newIngredients[index];
    newIngredients[index] = Ingredient(
        id: old.id,
        recipeId: old.recipeId,
        quantity: quantity ?? old.quantity,
        unit: unit ?? old.unit,
        name: name ?? old.name,
        preparation: prep ?? old.preparation);
    emit(state.copyWith(recipe: state.recipe.copyWith(ingredients: newIngredients)));
  }

  void removeIngredient(int index) {
    final newIngredients = List<Ingredient>.from(state.recipe.ingredients)
      ..removeAt(index);
    emit(state.copyWith(recipe: state.recipe.copyWith(ingredients: newIngredients)));
  }

  // --- INSTRUCTION METHODS ---
  void addInstruction() {
    final newInstructions = List<Instruction>.from(state.recipe.instructions)
      ..add(const Instruction(description: ''));
    emit(state.copyWith(
        recipe: state.recipe.copyWith(instructions: newInstructions)));
  }

  void updateInstruction(int index, String text, {int? duration}) {
    final newInstructions = List<Instruction>.from(state.recipe.instructions);
    newInstructions[index] = Instruction(
        description: text,
        durationInMinutes:
        duration ?? newInstructions[index].durationInMinutes);
    emit(state.copyWith(
        recipe: state.recipe.copyWith(instructions: newInstructions)));
  }

  void removeInstruction(int index) {
    final newInstructions = List<Instruction>.from(state.recipe.instructions)
      ..removeAt(index);
    emit(state.copyWith(
        recipe: state.recipe.copyWith(instructions: newInstructions)));
  }

  // --- TAGS METHODS ---
  void addTag(String tag) {
    final newTag = tag.trim().replaceAll(',', '');
    if (newTag.isNotEmpty && !state.recipe.tags.contains(newTag)) {
      final updatedTags = List<String>.from(state.recipe.tags)..add(newTag);
      emit(state.copyWith(recipe: state.recipe.copyWith(tags: updatedTags)));
    }
  }

  void removeTag(String tag) {
    final updatedTags = List<String>.from(state.recipe.tags)..remove(tag);
    emit(state.copyWith(recipe: state.recipe.copyWith(tags: updatedTags)));
  }

  Future<void> saveRecipe() async {
    final cleanRecipe = state.recipe.copyWith(
      ingredients: state.recipe.ingredients
          .where((i) => i.name.trim().isNotEmpty)
          .toList(),
      instructions: state.recipe.instructions
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
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImagePath = path.join(appDir.path, fileName);
      final file = File(pickedFile.path);
      await file.copy(savedImagePath);
      emit(state.copyWith(recipe: state.recipe.copyWith(imagePath: savedImagePath)));
    }
  }
}

class AddEditRecipeScreen extends StatelessWidget {
  final Recipe? recipe;

  const AddEditRecipeScreen({
    super.key,
    this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecipeFormCubit(
        context.read<RecipeRepository>(),
        recipe,
      ),
      child: Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: const _RecipeForm(),
            );
          },
        ),
      ),
    );
  }
}

class _RecipeForm extends StatefulWidget {
  const _RecipeForm();

  @override
  State<_RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<_RecipeForm> {
  // Controller to manage the tag input field
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RecipeFormCubit>();
    final recipeState = cubit.state;
    final recipe = recipeState.recipe;
    final isEditing = recipe.id != null;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ... (Header and Image picker UI is unchanged)
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            isEditing ? 'Edit Recipe' : 'Add New Recipe',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
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
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: recipe.imagePath != null && recipe.imagePath!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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

          // --- UPDATED TAGS SECTION ---
          _buildTagsSection(context, recipe.tags, recipeState.tagSuggestions),

          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Ingredients'),
          ..._buildIngredientsInputs(context, recipe.ingredients, cubit,
              recipe.id, recipeState.ingredientSuggestions),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Ingredient'),
            onPressed: () => cubit.addIngredient(),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Instructions'),
          ..._buildInstructionsInputs(context, recipe.instructions, cubit, recipe.id),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Step'),
            onPressed: () => cubit.addInstruction(),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              await cubit.saveRecipe();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text(
              'Save Recipe',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW WIDGET FOR TAGS WITH AUTOCOMPLETE ---
  Widget _buildTagsSection(
      BuildContext context, List<String> tags, List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isNotEmpty)
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: tags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  context.read<RecipeFormCubit>().removeTag(tag);
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return suggestions.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            context.read<RecipeFormCubit>().addTag(selection);
            // We need to clear the controller in fieldViewBuilder
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController fieldTextEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted) {
            return TextField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              decoration: InputDecoration(
                hintText: 'Add a tag...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    context
                        .read<RecipeFormCubit>()
                        .addTag(fieldTextEditingController.text);
                    fieldTextEditingController.clear();
                  },
                ),
              ),
              onSubmitted: (String value) {
                context.read<RecipeFormCubit>().addTag(value);
                fieldTextEditingController.clear();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  // --- UPDATED INGREDIENTS INPUTS ---
  List<Widget> _buildIngredientsInputs(
      BuildContext context,
      List<Ingredient> ingredients,
      RecipeFormCubit cubit,
      int? recipeId,
      List<String> suggestions) {
    return List.generate(ingredients.length, (index) {
      final ingredient = ingredients[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Autocomplete<String>(
                      initialValue: TextEditingValue(text: ingredient.name),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return suggestions.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        cubit.updateIngredient(index, name: selection);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        return _StyledTextField(
                          controller: controller,
                          focusNode: focusNode,
                          hintText: 'Ingredient Name',
                          onChanged: (v) => cubit.updateIngredient(index, name: v),
                        );
                      },
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
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error),
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
      return Padding(
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
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              onPressed: () => cubit.removeInstruction(index),
            ),
          ],
        ),
      );
    });
  }
}

// --- UPDATED _StyledTextField TO ACCEPT A CONTROLLER ---
class _StyledTextField extends StatelessWidget {
  final String? initialValue;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? labelText;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final int? maxLines;
  final TextStyle? style;

  const _StyledTextField({
    super.key,
    this.initialValue,
    this.controller,
    this.focusNode,
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
      controller: controller,
      focusNode: focusNode,
      style: style,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor =
    isPrimary ? colorScheme.primary : colorScheme.secondary;
    final foregroundColor =
    isPrimary ? colorScheme.onPrimary : colorScheme.onSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: foregroundColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 2),
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: foregroundColor,
            ),
            decoration: const InputDecoration(
              filled: false,
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