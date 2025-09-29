import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:suvai/data/models/meal_plan_model.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/data/repositories/meal_plan_repository.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/features/meal_planner/cubit/meal_planner_cubit.dart';
import 'package:suvai/features/meal_planner/cubit/meal_planner_state.dart';

class MealPlannerScreen extends StatelessWidget {
  const MealPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MealPlannerCubit(
        RepositoryProvider.of<MealPlanRepository>(context),
        RepositoryProvider.of<RecipeRepository>(context),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meal Planner'),
        ),
        body: const _MealPlannerView(),
      ),
    );
  }
}

class _MealPlannerView extends StatelessWidget {
  const _MealPlannerView();

  Future<void> _showSelectRecipeDialog(BuildContext context, DateTime date, MealType mealType) async {
    final cubit = context.read<MealPlannerCubit>();
    final allRecipes = cubit.state.recipeMap.values.toList();

    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select a Recipe'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allRecipes.length,
              itemBuilder: (context, index) {
                final recipe = allRecipes[index];
                return ListTile(
                  title: Text(recipe.name),
                  onTap: () => Navigator.of(dialogContext).pop(recipe),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedRecipe != null && context.mounted) {
      cubit.addRecipeToPlan(selectedRecipe, date, mealType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<MealPlannerCubit>();
    final state = cubit.state;
    final weekStart = state.displayedWeekDate;
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Column(
      children: [
        // Header with week navigation
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => cubit.goToPreviousWeek(),
              ),
              Text(
                '${DateFormat.MMMMd().format(weekStart)} - ${DateFormat.MMMMd().format(weekEnd)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => cubit.goToNextWeek(),
              ),
            ],
          ),
        ),
        // The main list of days
        Expanded(
          child: ListView.builder(
            itemCount: 7, // 7 days in a week
            itemBuilder: (context, dayIndex) {
              final date = weekStart.add(Duration(days: dayIndex));
              return _DayCard(date: date);
            },
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime date;
  const _DayCard({required this.date});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(date),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ...MealType.values.map((mealType) {
              return _MealSlotRow(date: date, mealType: mealType);
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _MealSlotRow extends StatelessWidget {
  final DateTime date;
  final MealType mealType;

  const _MealSlotRow({
    required this.date,
    required this.mealType,
  });

  // Helper method from the old layout, now used here
  Future<void> _showSelectRecipeDialog(BuildContext context, DateTime date, MealType mealType) async {
    final cubit = context.read<MealPlannerCubit>();
    final allRecipes = cubit.state.recipeMap.values.toList();

    final selectedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select a Recipe'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allRecipes.length,
              itemBuilder: (context, index) {
                final recipe = allRecipes[index];
                return ListTile(
                  title: Text(recipe.name),
                  onTap: () => Navigator.of(dialogContext).pop(recipe),
                );
              },
            ),
          ),
        );
      },
    );

    if (selectedRecipe != null && context.mounted) {
      cubit.addRecipeToPlan(selectedRecipe, date, mealType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<MealPlannerCubit>();
    final state = cubit.state;

    const mealTypeDetails = {
      MealType.breakfast: {'name': 'Breakfast', 'color': Color(0xFF8294C4)},
      MealType.morningSnack: {'name': 'M. Snack', 'color': Color(0xFFA0BFE0)},
      MealType.lunch: {'name': 'Lunch', 'color': Color(0xFFDBDFEA)},
      MealType.eveningSnack: {'name': 'E. Snack', 'color': Color(0xFFACB1D6)},
      MealType.dinner: {'name': 'Dinner', 'color': Color(0xFFDBDFEA)},
    };

    final entry = state.mealPlanEntries.firstWhereOrNull(
          (e) => e.date.day == date.day && e.date.month == date.month && e.mealType == mealType,
    );
    final details = mealTypeDetails[mealType]!;

    return InkWell(
      onTap: () {
        if (entry == null) {
          _showSelectRecipeDialog(context, date, mealType);
        } else {
          // TODO: Handle tapping on an existing entry
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: details['color'] as Color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                details['name'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: entry != null
                  ? Text(
                state.recipeMap[entry.recipeId]?.name ?? 'Recipe not found',
                style: const TextStyle(fontSize: 16),
              )
                  : const Icon(Icons.add_circle_outline, color: Colors.white54, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}