import 'dart:io'; // Required for Platform checks
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Required for FFI initialization
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/features/recipe_book/views/recipe_list_screen.dart';
import 'package:suvai/core/router/app_router.dart';
import 'package:suvai/data/repositories/meal_plan_repository.dart';


Future<void> main() async { // main function now needs to be async
  // This is needed to ensure that plugins are initialized before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // --- ADD THIS BLOCK ---
  // Initialize FFI for sqflite on desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // --- END OF BLOCK ---

  runApp(const SuvaiApp());
}

class SuvaiApp extends StatelessWidget {
  const SuvaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => RecipeRepository(),
        ),
        RepositoryProvider(
          create: (context) => MealPlanRepository(), // <-- 3. Add the new repository
        ),
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