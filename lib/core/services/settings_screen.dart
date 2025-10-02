// lib/features/settings/views/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suvai/core/services/backup_service.dart';
import 'package:suvai/data/repositories/recipe_repository.dart';
import 'package:suvai/features/recipe_book/cubit/recipe_list_cubit.dart';
import 'package:suvai/main.dart'; // Import main.dart to access AppColors

class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<SettingsDrawer> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final backupService = BackupService(context.read<RecipeRepository>());
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- UPDATED DRAWERHEADER ---
          SizedBox( // Use SizedBox to control height
            height: 120, // Reduced height
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary, // This will be your primaryRed
              ),
              child: Align( // Align text to the bottom-left
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Suvai Settings',
                  style: theme.textTheme.headlineSmall?.copyWith( // Slightly smaller text
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            leading: _isBackingUp
                ? const CircularProgressIndicator()
                : const Icon(Icons.backup_outlined),
            title: const Text('Backup Recipes'),
            subtitle: const Text('Save all your recipes to a single file.'),
            onTap: _isBackingUp || _isRestoring
                ? null
                : () async {
              setState(() => _isBackingUp = true);
              final success = await backupService.createBackup();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Backup created successfully!'
                        : 'Backup failed or was cancelled.'),
                    backgroundColor:
                    success ? Colors.green : Colors.red,
                  ),
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) setState(() => _isBackingUp = false);
                });
              }
            },
          ),
          ListTile(
            leading: _isRestoring
                ? const CircularProgressIndicator()
                : const Icon(Icons.restore_page_outlined),
            title: const Text('Restore Recipes'),
            subtitle: const Text('Load recipes from a backup file.'),
            onTap: _isBackingUp || _isRestoring
                ? null
                : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Restore Recipes?'),
                  content: const Text(
                      'This will add all recipes from the backup file. Continue?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Restore')),
                  ],
                ),
              );

              if (confirmed == true) {
                setState(() => _isRestoring = true);
                final count = await backupService.restoreBackup();
                if (mounted) {
                  context.read<RecipeListCubit>().loadRecipes();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(count > 0
                          ? '$count recipes restored successfully!'
                          : 'Restore failed or was cancelled.'),
                      backgroundColor:
                      count > 0 ? Colors.green : Colors.red,
                    ),
                  );
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) setState(() => _isRestoring = false);
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }
}