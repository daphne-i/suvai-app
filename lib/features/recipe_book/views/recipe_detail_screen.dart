import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/features/recipe_book/cubit/detail/recipe_detail_cubit.dart';
import 'package:suvai/features/recipe_book/cubit/detail/recipe_detail_state.dart';

class RecipeDetailScreen extends StatelessWidget {
  final int recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecipeDetailCubit(
        context.read<RecipeRepository>(),
      )..loadRecipe(recipeId),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
              builder: (context, state) {
                if (state.status == RecipeDetailStatus.success && state.recipe != null) {
                  return IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Recipe',
                    onPressed: () {
                      context.push('/edit-recipe', extra: state.recipe);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
          builder: (context, state) {
            if (state.status == RecipeDetailStatus.loading || state.status == RecipeDetailStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == RecipeDetailStatus.failure || state.recipe == null) {
              return Center(child: Text(state.errorMessage));
            }

            final recipe = state.recipe!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoChip(
                          icon: Icons.group_outlined,
                          label: 'Serves',
                          value: recipe.servings.toString(),
                        ),
                        _InfoChip(
                          icon: Icons.timer_outlined,
                          label: 'Prep time',
                          value: '${recipe.prepTimeMinutes} min',
                        ),
                        _InfoChip(
                          icon: Icons.whatshot_outlined,
                          label: 'Cook time',
                          value: '${recipe.cookTimeMinutes} min',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                          colors: [Colors.orange.shade600, Colors.red.shade500]
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () {
                        context.push('/cook', extra: recipe);
                      },
                      child: const Text('Start Cooking', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  for (final ingredient in recipe.ingredients)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('• ${_formatQuantity(ingredient.quantity)} ${ingredient.unit} ${ingredient.name}'),
                    ),
                  const SizedBox(height: 24),
                  Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  for (int i = 0; i < recipe.instructions.length; i++)
                    ListTile(
                      leading: Text('${i + 1}.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      title: Text(recipe.instructions[i]),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.white70),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}