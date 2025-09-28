import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
      ),
    ),
  ],
);