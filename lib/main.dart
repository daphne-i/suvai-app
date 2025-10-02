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

        // --- UPDATED LIGHT THEME ---
        theme: ThemeData(
          brightness: Brightness.light,
          // Corrected Color Scheme
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ).copyWith(
            primary: Colors.orange.shade700, // Enforce a specific orange shade
          ),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
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
          // Updated to use the new primary color
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            unselectedItemColor: Colors.grey.shade600,
          ),
          useMaterial3: true,
        ),

        // --- UPDATED DARK THEME ---
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          // Corrected Color Scheme
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.dark,
          ).copyWith(
            primary: Colors.orange.shade400, // Enforce a specific orange shade
          ),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardTheme: CardThemeData(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            hintStyle: TextStyle(color: Colors.grey.shade700),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          // Updated to use the new primary color
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF1E1E1E),
            unselectedItemColor: Colors.grey,
          ),
          useMaterial3: true,
        ),
      ),
    ));
  }
}