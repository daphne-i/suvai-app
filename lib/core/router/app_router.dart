import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/features/recipe_book/views/add_edit_recipe_screen.dart';
import 'package:suvai/features/recipe_book/views/recipe_list_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const RecipeListScreen(),
    ),
    GoRoute(
      path: '/add-recipe',
      builder: (context, state) => AddEditRecipeScreen(
        // Provide the repository to the new screen
        recipeRepository: RepositoryProvider.of<RecipeRepository>(context),
        recipe: null,
      ),
    ),
    GoRoute(
      path: '/edit-recipe', // For editing an existing recipe
      builder: (context, state) {
        // The recipe to edit is passed as an 'extra' parameter
        final recipe = state.extra as Recipe;
        return AddEditRecipeScreen(
          recipeRepository: RepositoryProvider.of<RecipeRepository>(context),
          recipe: recipe, // Pass the existing recipe to the form
        );
      },
    ),
  ],
);