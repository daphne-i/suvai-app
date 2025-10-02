import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/features/recipe_book/cubit/recipe_list_cubit.dart';
import 'package:suvai/features/recipe_book/cubit/recipe_list_state.dart';
import 'dart:io';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget is responsible for CREATING and PROVIDING the Cubit.
    return BlocProvider(
      create: (context) => RecipeListCubit(
        RepositoryProvider.of<RecipeRepository>(context),
      )..loadRecipes(),
      // Its child is the widget that will build the UI.
      child: const _RecipeListView(),
    );
  }
}

// This widget's BuildContext is a DESCENDANT of the BlocProvider,
// so it can successfully find and use the RecipeListCubit.
class _RecipeListView extends StatelessWidget {
  const _RecipeListView();

  @override
  Widget build(BuildContext context) {
    // Use BlocSelector to rebuild only when the activeTagFilter changes
    final activeTagFilter = context.select((RecipeListCubit cubit) => cubit.state.activeTagFilter);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'My Recipes (சுவை)',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  prefixIcon: const Icon(Icons.search),


                             ),
                onChanged: (value) {
                  context.read<RecipeListCubit>().searchQueryChanged(value);
                },
              ),
              if (activeTagFilter != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Chip(
                    label: Text('Filtering by: "$activeTagFilter"'),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    onDeleted: () {
                      context.read<RecipeListCubit>().clearTagFilter();
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
                    if (state.status == RecipeListStatus.failure) {
                      return Center(child: Text('Failed to load recipes: ${state.errorMessage}'));
                    }
                    if (state.filteredRecipes.isEmpty) {
                      return const Center(
                        child: Text(
                          'No recipes found.',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 80.0), // Space for FAB
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
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
      floatingActionButton:
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.orange.shade600, Colors.red.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      child: FloatingActionButton(
        heroTag: 'fab_recipe_list',
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () async {
          await context.push('/add-recipe');
          context.read<RecipeListCubit>().loadRecipes();
        },
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    ));
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await context.push('/recipe/${recipe.id}');
        context.read<RecipeListCubit>().loadRecipes();
      },
      onLongPress: () {
        _showDeleteConfirmation(context, recipe);
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: recipe.imagePath != null && recipe.imagePath!.isNotEmpty
                  ? Image.file(
                File(recipe.imagePath!),
                fit: BoxFit.cover,
              )
                  : Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(Icons.photo_camera, color: Colors.white38, size: 50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                recipe.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
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