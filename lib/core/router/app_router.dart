import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/core/router/scaffold_with_nav_bar.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/features/recipe_book/views/add_edit_recipe_screen.dart';
import 'package:suvai/features/recipe_book/views/recipe_list_screen.dart';
import 'package:suvai/features/meal_planner/views/meal_planner_screen.dart'; // <-- Import new screen

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  initialLocation: '/recipes',
  navigatorKey: _rootNavigatorKey,
  routes: [
    // This ShellRoute builds the UI with the BottomNavigationBar
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Branch for the first tab (Recipes)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => const RecipeListScreen(),
            ),
          ],
        ),
        // Branch for the second tab (Planner)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/planner',
              builder: (context, state) => const MealPlannerScreen(),
            ),
          ],
        ),
      ],
    ),
    // These are top-level routes that will cover the navigation bar
    GoRoute(
      path: '/add-recipe',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => AddEditRecipeScreen(
        recipeRepository: RepositoryProvider.of<RecipeRepository>(context),
        recipe: null,
      ),
    ),
    GoRoute(
      path: '/edit-recipe',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final recipe = state.extra as Recipe;
        return AddEditRecipeScreen(
          recipeRepository: RepositoryProvider.of<RecipeRepository>(context),
          recipe: recipe,
        );
      },
    ),
  ],
);