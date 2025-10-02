import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:suvai/core/router/app_router.dart';
import 'package:suvai/data/repositories/meal_plan_repository.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/data/repositories/shopping_list_repository.dart';
import 'package:suvai/features/recipe_book/cubit/recipe_list_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final recipeRepository = RecipeRepository();
  final mealPlanRepository = MealPlanRepository();
  final shoppingListRepository = ShoppingListRepository(
    mealPlanRepository,
    recipeRepository,
  );

  runApp(
    SuvaiApp(
      recipeRepository: recipeRepository,
      mealPlanRepository: mealPlanRepository,
      shoppingListRepository: shoppingListRepository,
    ),
  );
}

class SuvaiApp extends StatelessWidget {
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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: recipeRepository),
        RepositoryProvider.value(value: mealPlanRepository),
        RepositoryProvider.value(value: shoppingListRepository),
      ],
      child: BlocProvider<RecipeListCubit>(
        create: (context) => RecipeListCubit(
          context.read<RecipeRepository>(),
        )..loadRecipes(),
        child: MaterialApp.router(
          routerConfig: goRouter,
          title: 'Suvai',
          themeMode: ThemeMode.system,

          // --- NEW LIGHT THEME ---
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4A85A4), // Steel Blue
              brightness: Brightness.light,
              secondary: const Color(0xFFA4D4D9), // Light Blue
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
            scaffoldBackgroundColor: const Color(0xFFF0F7F4), // Off-white
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          // --- NEW DARK THEME ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4A85A4), // Steel Blue
              brightness: Brightness.dark,
              secondary: const Color(0xFFA4D4D9), // Light Blue
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF1c2128), // Dark Blue-Gray from palette
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              color: const Color(0xFF2d333b), // Slightly lighter gray
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2d333b),
              hintStyle: TextStyle(color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}