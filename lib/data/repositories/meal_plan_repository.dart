import 'package:intl/intl.dart'; // <-- Add import
import 'package:suvai/core/database/database_service.dart';
import 'package:suvai/data/models/meal_plan_model.dart';

class MealPlanRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<List<MealPlanEntry>> getMealPlansForWeek(DateTime weekStartDate) async {
    final db = await _dbService.database;
    final weekEndDate = weekStartDate.add(const Duration(days: 6));

    final List<Map<String, dynamic>> maps = await db.query(
      'meal_plan',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        DateFormat('yyyy-MM-dd').format(weekStartDate),
        DateFormat('yyyy-MM-dd').format(weekEndDate),
      ],
    );

    return List.generate(maps.length, (i) {
      return MealPlanEntry(
        id: maps[i]['id'],
        date: DateTime.parse(maps[i]['date']),
        mealType: MealType.values.firstWhere((e) => e.toString() == 'MealType.${maps[i]['mealType']}'),
        recipeId: maps[i]['recipeId'],
      );
    });
  }
  Future<void> addMealPlanEntry(MealPlanEntry entry) async {
    final db = await _dbService.database;
    await db.insert(
      'meal_plan',
      {
        'date': DateFormat('yyyy-MM-dd').format(entry.date),
        'mealType': entry.mealType.name,
        'recipeId': entry.recipeId,
      },
    );
  }
}