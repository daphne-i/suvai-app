import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // Import this to check the platform
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/data/models/ingredient_model.dart';
import 'package:suvai/data/models/instruction_model.dart';

class BackupService {
  final RecipeRepository _recipeRepository;

  BackupService(this._recipeRepository);

  Future<bool> createBackup() async {
    // This method is already platform-agnostic and correct.
    try {
      final recipes = await _recipeRepository.getAllRecipes();
      if (recipes.isEmpty) {
        return false;
      }

      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Your Backup',
        fileName:
        'suvai_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (outputPath == null) {
        return false;
      }

      final encoder = ZipFileEncoder();
      encoder.create(outputPath);

      final recipesJson = jsonEncode(recipes.map((r) {
        return {
          'name': r.name,
          'imagePath': r.imagePath != null ? p.basename(r.imagePath!) : null,
          'servings': r.servings,
          'prepTimeMinutes': r.prepTimeMinutes,
          'cookTimeMinutes': r.cookTimeMinutes,
          'ingredients': r.ingredients.map((i) => i.toMap()).toList(),
          'instructions': r.instructions.map((i) => i.toJson()).toList(),
          'tags': r.tags,
        };
      }).toList());

      encoder.addArchiveFile(ArchiveFile('recipes.json',
          utf8.encode(recipesJson).length, utf8.encode(recipesJson)));

      for (final recipe in recipes) {
        if (recipe.imagePath != null && File(recipe.imagePath!).existsSync()) {
          final imageFile = File(recipe.imagePath!);
          await encoder.addFile(
              imageFile, 'images/${p.basename(imageFile.path)}');
        }
      }

      encoder.close();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Error creating backup: $e');
      return false;
    }
  }

  Future<int> restoreBackup() async {
    try {
      // --- NEW: PLATFORM-AWARE PERMISSION LOGIC ---
      bool permissionsGranted = false;

      // Check if we are on a mobile platform (iOS or Android)
      if (kIsWeb) {
        permissionsGranted = true; // No permissions needed for web
      } else if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.status;
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
        if (status.isPermanentlyDenied) {
          // Consider showing a dialog to guide the user to app settings
          print("Storage permission is permanently denied.");
        }
        permissionsGranted = status.isGranted;
      } else {
        // Assume desktop platforms (Windows, macOS, Linux) don't need explicit permissions
        permissionsGranted = true;
      }

      if (!permissionsGranted) {
        print("Storage permissions were not granted.");
        return 0; // Abort if permissions are not granted on mobile
      }
      // --- END OF PERMISSION LOGIC ---

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) {
        print("File picking cancelled by user.");
        return 0;
      }

      final file = File(result.files.single.path!);
      final archive = ZipDecoder().decodeBytes(file.readAsBytesSync());

      final recipesFile = archive.findFile('recipes.json');
      if (recipesFile == null) {
        print("Error: recipes.json not found in the backup file.");
        return 0;
      }

      final recipesJson = utf8.decode(recipesFile.content as List<int>);
      final List<dynamic> recipeList = jsonDecode(recipesJson);

      final appDir = await getApplicationDocumentsDirectory();
      int restoredCount = 0;

      for (final recipeData in recipeList) {
        String? newImagePath;
        if (recipeData['imagePath'] != null) {
          final imageFile =
          archive.findFile('images/${recipeData['imagePath']}');
          if (imageFile != null) {
            final newPath = p.join(appDir.path, recipeData['imagePath']);
            final newFile = File(newPath);
            await newFile.writeAsBytes(imageFile.content as List<int>);
            newImagePath = newPath;
          }
        }

        final recipe = Recipe(
          name: recipeData['name'],
          imagePath: newImagePath,
          servings: recipeData['servings'],
          prepTimeMinutes: recipeData['prepTimeMinutes'],
          cookTimeMinutes: recipeData['cookTimeMinutes'],
          ingredients: (recipeData['ingredients'] as List)
              .map((i) => Ingredient.fromMap(i))
              .toList(),
          instructions: (recipeData['instructions'] as List)
              .map((i) => Instruction.fromJson(i))
              .toList(),
          tags: List<String>.from(recipeData['tags']),
        );

        await _recipeRepository.insertRecipe(recipe);
        restoredCount++;
      }
      print("$restoredCount recipes were restored.");
      return restoredCount;
    } catch (e) {
      // ignore: avoid_print
      print('Error restoring backup: $e');
      return 0;
    }
  }
}