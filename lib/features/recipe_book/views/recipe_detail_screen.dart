import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/features/recipe_book/cubit/detail/recipe_detail_cubit.dart';
import 'package:suvai/features/recipe_book/cubit/detail/recipe_detail_state.dart';
import 'package:suvai/features/recipe_book/cubit/recipe_list_cubit.dart';
import 'package:suvai/features/recipe_book/views/add_edit_recipe_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final int recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecipeDetailCubit(
        context.read<RecipeRepository>(),
      )..loadRecipe(recipeId),
      child: const _RecipeDetailSheetContent(),
    );
  }
}

class _RecipeDetailSheetContent extends StatelessWidget {
  const _RecipeDetailSheetContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
      builder: (context, state) {
        if (state.status == RecipeDetailStatus.loading || state.status == RecipeDetailStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == RecipeDetailStatus.failure || state.recipe == null) {
          return Center(child: Text(state.errorMessage));
        }

        final recipe = state.recipe!;
        final theme = Theme.of(context);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250.0,
                  pinned: true,
                  stretch: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  iconTheme: const IconThemeData(
                    color: Colors.white,
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      recipe.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black87,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    centerTitle: true,
                    titlePadding: const EdgeInsets.only(left: 48, right: 48, bottom: 16),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (recipe.imagePath != null && recipe.imagePath!.isNotEmpty)
                          Image.file(
                            File(recipe.imagePath!),
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            color: theme.colorScheme.primaryContainer,
                            child: Center(
                              child: Icon(
                                Icons.fastfood_outlined,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 80,
                              ),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit Recipe',
                      onPressed: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          // --- THIS IS THE CORRECTED LINE ---
                          builder: (_) => AddEditRecipeScreen(recipe: recipe),
                        ).then((_) {
                          context.read<RecipeListCubit>().loadRecipes();
                        });
                      },
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push('/cook', extra: recipe);
                          },
                          child: const Text('Start Cooking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 24),
                        Text('Ingredients', style: theme.textTheme.titleLarge),
                        const Divider(height: 24),
                        for (final ingredient in recipe.ingredients)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text('• ${_formatQuantity(ingredient.quantity)} ${ingredient.unit} ${ingredient.name}'),
                          ),
                        const SizedBox(height: 24),
                        Text('Instructions', style: theme.textTheme.titleLarge),
                        const Divider(height: 24),
                        ...recipe.instructions.map((instruction) {
                          final index = recipe.instructions.indexOf(instruction);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Text('${index + 1}.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            title: Text(instruction.description),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 28, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}