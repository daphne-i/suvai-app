// lib/features/recipe_book/views/recipe_list_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/features/recipe_book/cubit/recipe_list_cubit.dart';
import 'package:suvai/features/recipe_book/cubit/recipe_list_state.dart';
import 'package:suvai/features/recipe_book/views/add_edit_recipe_screen.dart';
import 'package:suvai/features/recipe_book/views/recipe_detail_screen.dart';

import '../../../core/services/settings_screen.dart';
// Import the settings drawer



class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RecipeListView();
  }
}

class _RecipeListView extends StatelessWidget {
  const _RecipeListView();

  @override
  Widget build(BuildContext context) {
    final activeTagFilter = context.select((RecipeListCubit cubit) => cubit.state.activeTagFilter);
    final theme = Theme.of(context);

    return Scaffold(
      // --- ADD THE DRAWER HERE ---
      drawer: const SettingsDrawer(),
      appBar: AppBar(
        // The default hamburger icon will appear automatically.
        // You can remove the settings icon from actions if you want.
        title: Text(
          'My Recipes (சுவை)',
          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        top: false, // AppBar provides top safety
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search recipes...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  context.read<RecipeListCubit>().searchQueryChanged(value);
                },
              ),
              if (activeTagFilter != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Chip(
                    label: Text('Filtering by: "$activeTagFilter"'),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    onDeleted: () {
                      context.read<RecipeListCubit>().clearTagFilter();
                    },
                  ),
                ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<RecipeListCubit, RecipeListState>(
                  builder: (context, state) {
                    if (state.status == RecipeListStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == RecipeListStatus.failure) {
                      return Center(child: Text('Failed to load recipes: ${state.errorMessage}'));
                    }
                    if (state.filteredRecipes.isEmpty) {
                      return const Center(
                        child: Text(
                          'No recipes found.',
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: state.filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = state.filteredRecipes[index];
                        return _RecipeCard(recipe: recipe);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 56.0,
        height: 56.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.orange.shade600, Colors.red.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'fab_recipe_list',
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddEditRecipeScreen(),
            ).then((_) {
              context.read<RecipeListCubit>().loadRecipes();
            });
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

// ... _RecipeCard and _showDeleteConfirmation remain unchanged ...
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SizedBox(
              height: MediaQuery.of(context).size.height * 0.9,
              child: RecipeDetailScreen(recipeId: recipe.id!),
            ),
          );
        },
        onLongPress: () {
          _showDeleteConfirmation(context, recipe);
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            if (recipe.imagePath != null && recipe.imagePath!.isNotEmpty)
              Positioned.fill(
                child: Image.file(
                  File(recipe.imagePath!),
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    size: 50,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                recipe.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showDeleteConfirmation(BuildContext context, Recipe recipe) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Delete Recipe?'),
        content: Text('Are you sure you want to delete "${recipe.name}"? This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
            onPressed: () {
              context.read<RecipeListCubit>().deleteRecipe(recipe.id!);
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}