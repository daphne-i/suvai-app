import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:suvai/core/router/app_router.dart';
import 'package:suvai/data/repositories/meal_plan_repository.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/data/repositories/shopping_list_repository.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // --- 1. CREATE ALL REPOSITORIES MANUALLY HERE ---
  final recipeRepository = RecipeRepository();
  final mealPlanRepository = MealPlanRepository();
  final shoppingListRepository = ShoppingListRepository(
    mealPlanRepository,
    recipeRepository,
  );

  runApp(
    // --- 2. PASS THE REPOSITORIES TO THE APP WIDGET ---
    SuvaiApp(
      recipeRepository: recipeRepository,
      mealPlanRepository: mealPlanRepository,
      shoppingListRepository: shoppingListRepository,
    ),
  );
}

class SuvaiApp extends StatelessWidget {
  // --- 3. ADD CONSTRUCTOR AND PROPERTIES FOR THE REPOSITORIES ---
  final RecipeRepository recipeRepository;
  final MealPlanRepository mealPlanRepository;
  final ShoppingListRepository shoppingListRepository;

  const SuvaiApp({
    super.key,
    required this.recipeRepository,
    required this.mealPlanRepository,
    required this.shoppingListRepository,
  });

  @override
  Widget build(BuildContext context) {

    // --- 4. USE .value CONSTRUCTORS TO PROVIDE THE EXISTING INSTANCES ---
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: recipeRepository),
        RepositoryProvider.value(value: mealPlanRepository),
        RepositoryProvider.value(value: shoppingListRepository),
      ],
      child: MaterialApp.router(
        routerConfig: goRouter,
        title: 'Suvai',
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.orange,
          colorScheme: const ColorScheme.dark(
            primary: Colors.orange,
            secondary: Colors.redAccent,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardTheme: CardThemeData(
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.redAccent,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}