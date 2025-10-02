import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/features/recipe_book/cubit/recipe_list_cubit.dart';
import 'package:suvai/features/recipe_book/cubit/recipe_list_state.dart';
import 'package:suvai/features/recipe_book/views/add_edit_recipe_screen.dart';
import 'package:suvai/features/recipe_book/views/recipe_detail_screen.dart';
import 'package:suvai/core/services/settings_screen.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const SettingsDrawer(),
      appBar: AppBar(
        title: Text(
          'My Recipes (சுவை)',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search recipes...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  context.read<RecipeListCubit>().searchQueryChanged(value);
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<RecipeListCubit, RecipeListState>(
                builder: (context, state) {
                  if (state.status == RecipeListStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.filteredRecipes.isEmpty) {
                    return const Center(
                      child: Text('No recipes found.'),
                    );
                  }

                  // --- NEW GROUPING LOGIC ---
                  final groupedRecipes = <String, List<Recipe>>{};
                  for (var recipe in state.filteredRecipes) {
                    for (var tag in recipe.tags) {
                      (groupedRecipes[tag] ??= []).add(recipe);
                    }
                  }
                  final sortedTags = groupedRecipes.keys.sorted();

                  // --- NEW CATEGORY LISTVIEW ---
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: sortedTags.length,
                    itemBuilder: (context, index) {
                      final tag = sortedTags[index];
                      final recipesInGroup = groupedRecipes[tag]!;
                      return _CategoryRow(
                        tag: tag,
                        recipes: recipesInGroup,
                        allRecipes: state.recipes,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56.0,
        height: 56.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFFEF4747),
              Color(0xFFD93A3A)
            ], // Vibrant Red -> Darker Red
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

class _CategoryRow extends StatelessWidget {
  final String tag;
  final List<Recipe> recipes;
  final List<Recipe> allRecipes;

  const _CategoryRow({
    required this.tag,
    required this.recipes,
    required this.allRecipes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tag,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  context.push('/recipes-by-tag', extra: {'tag': tag, 'recipes': allRecipes});
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220, // Define a fixed height for the horizontal list
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 170, // Define a fixed width for the cards
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _RecipeCard(recipe: recipes[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

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
        content: Text(
            'Are you sure you want to delete "${recipe.name}"? This cannot be undone.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
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