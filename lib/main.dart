import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
          // Set the overall brightness to dark
          brightness: Brightness.light,
          // Use Poppins font for the whole app
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme.apply(bodyColor: Colors.black87)),

          // Define the core color scheme
          colorScheme: const ColorScheme.light(
            primary: Colors.orange,
            secondary: Colors.redAccent,
          ),

          // Set the main background color
          scaffoldBackgroundColor: Colors.white,

          // Style for all cards in the app
          cardTheme: CardThemeData(
            elevation: 5,
          //  color: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),

          // Style for all text input fields
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade100,
            hintStyle: TextStyle(color: Colors.grey.shade700),
            labelStyle: const TextStyle(color: Colors.black54), // For when the label is not focused
            floatingLabelStyle: const TextStyle(color: Colors.black54), // For when the label is floating
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
           // backgroundColor: Colors.orange.shade600, // Set a base color
            shape: const CircleBorder(), // Enforce a circular shape globally
          ),
          useMaterial3: true,
        ),
      ),
    );
  }
}