// lib/features/recipe_book/views/tagged_recipe_list_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/features/recipe_book/views/recipe_detail_screen.dart';

class TaggedRecipeListScreen extends StatelessWidget {
  final String tag;
  final List<Recipe> allRecipes;

  const TaggedRecipeListScreen({
    super.key,
    required this.tag,
    required this.allRecipes,
  });

  @override
  Widget build(BuildContext context) {
    // Filter the recipes that contain the selected tag
    final taggedRecipes = allRecipes.where((recipe) => recipe.tags.contains(tag)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tag),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.8,
        ),
        itemCount: taggedRecipes.length,
        itemBuilder: (context, index) {
          final recipe = taggedRecipes[index];
          // We can reuse the _RecipeCard widget from the main list screen
          return _RecipeCard(recipe: recipe);
        },
      ),
    );
  }
}

// Re-using a simplified version of the Recipe Card here for consistency
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