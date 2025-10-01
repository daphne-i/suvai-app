import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:suvai/core/router/scaffold_with_nav_bar.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/features/meal_planner/views/meal_planner_screen.dart';
import 'package:suvai/features/recipe_book/views/add_edit_recipe_screen.dart';
import 'package:suvai/features/recipe_book/views/recipe_list_screen.dart';
import 'package:suvai/features/shopping_list/views/shopping_list_screen.dart';

// 1. Add keys for the shell route and each branch
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKeyRecipes = GlobalKey<NavigatorState>(debugLabel: 'RecipesShell');
final _shellNavigatorKeyPlanner = GlobalKey<NavigatorState>(debugLabel: 'PlannerShell');
final _shellNavigatorKeyShopping = GlobalKey<NavigatorState>(debugLabel: 'ShoppingShell');

final goRouter = GoRouter(
  initialLocation: '/recipes',
  navigatorKey: _rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Branch for the first tab (Recipes)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyRecipes, // 2. Assign the key
          routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => const RecipeListScreen(),
            ),
          ],
        ),
        // Branch for the second tab (Planner)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyPlanner, // 2. Assign the key
          routes: [
            GoRoute(
              path: '/planner',
              builder: (context, state) => const MealPlannerScreen(),
            ),
          ],
        ),
        // Branch for the third tab (Shopping)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKeyShopping, // 2. Assign the key
          routes: [
            GoRoute(
              path: '/shopping',
              builder: (context, state) => const ShoppingListScreen(),
            ),
          ],
        ),
      ],
    ),
    // These routes will cover the bottom nav bar
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