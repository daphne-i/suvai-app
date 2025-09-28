import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        // Assuming RecipeRepository is provided higher up the tree in main.dart
        RepositoryProvider.of<RecipeRepository>(context),
      )..loadRecipes(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Recipes (சுவை)'),
          // The search bar will be added when we implement the search user story [cite: 40]
        ),
        body: BlocBuilder<RecipeListCubit, RecipeListState>(
          builder: (context, state) {
            if (state.status == RecipeListStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == RecipeListStatus.failure) {
              return Center(child: Text('Failed to load recipes: ${state.errorMessage}'));
            }

            if (state.status == RecipeListStatus.success && state.recipes.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Your recipe book is empty. Tap the + button to add your first recipe!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ),
              );
            }

            // --- UI CHANGE FROM LISTVIEW TO GRIDVIEW ---
            return GridView.builder(
              padding: const EdgeInsets.all(12.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,          // 2 columns
                crossAxisSpacing: 12.0,     // Horizontal spacing
                mainAxisSpacing: 12.0,      // Vertical spacing
                childAspectRatio: 0.8,      // Aspect ratio of each card
              ),
              itemCount: state.recipes.length,
              itemBuilder: (context, index) {
                final recipe = state.recipes[index];
                return _RecipeCard(recipe: recipe);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Navigate to Add Recipe Screen
          },
          child: const Icon(Icons.add, size: 32),
        ),
      ),
    );
  }
}

// --- NEW WIDGET FOR THE RECIPE CARD ---
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // Ensures the content respects the card's rounded corners
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[800],
              // Later, we'll replace this with an Image widget once we can add photos.
              // For now, a placeholder indicates where the image will go.
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