import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import '../cubit/recipe_list_cubit.dart';
import '../cubit/recipe_list_state.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecipeListCubit(
        RepositoryProvider.of<RecipeRepository>(context),
      )..loadRecipes(),
      child: Scaffold(
        // We remove the AppBar to have more control over the layout
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Main Title
                Text(
                  'My Recipes (சுவை)',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // --- NEW SEARCH BAR WIDGET ---
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search recipes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    // Connects the search bar to our cubit
                    context.read<RecipeListCubit>().searchQueryChanged(value);
                  },
                ),
                const SizedBox(height: 16),

                // --- GRID VIEW ---
                Expanded(
                  child: BlocBuilder<RecipeListCubit, RecipeListState>(
                    builder: (context, state) {
                      if (state.status == RecipeListStatus.loading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state.status == RecipeListStatus.failure) {
                        return Center(child: Text('Failed to load recipes: ${state.errorMessage}'));
                      }

                      // Check the filtered list now
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
                        // Use the filtered list for the UI
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            GoRouter.of(context).go('/add-recipe');
          },
          child: const Icon(Icons.add, size: 32),
        ),
      ),
    );
  }
}

// The _RecipeCard widget remains unchanged from the previous step
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}