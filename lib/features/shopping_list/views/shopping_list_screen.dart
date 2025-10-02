import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suvai/data/models/shopping_list_item_model.dart';
import 'package:suvai/data/repositories/shopping_list_repository.dart';
import 'package:suvai/features/shopping_list/cubit/shopping_list_cubit.dart';
import 'package:suvai/features/shopping_list/cubit/shopping_list_state.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ShoppingListCubit(
        context.read<ShoppingListRepository>(),
      ),
      child: const _ShoppingListView(),
    );
  }
}

class _ShoppingListView extends StatelessWidget {
  const _ShoppingListView();

  Future<void> _showAddManualItemDialog(BuildContext context) async {
    final textController = TextEditingController();
    final cubit = context.read<ShoppingListCubit>();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Manual Item'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'e.g., Paper Towels'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                cubit.addManualItem(textController.text);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping List',
          style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocBuilder<ShoppingListCubit, ShoppingListState>(
            builder: (context, state) {
              if (state.groupedItems.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Clear List',
                  onPressed: () {
                    context.read<ShoppingListCubit>().clearList();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 56.0,
        height: 56.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4747), Color(0xFFD93A3A)], // Vibrant Red -> Darker Red
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'fab_shopping_list',
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          onPressed: () {
            _showAddManualItemDialog(context);
          },
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Generate from Current Week\'s Plan'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: () {
                context.read<ShoppingListCubit>().generateList();
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<ShoppingListCubit, ShoppingListState>(
              builder: (context, state) {
                if (state.status == ShoppingListStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == ShoppingListStatus.failure) {
                  return Center(child: Text('Error: ${state.errorMessage}'));
                }
                if ((state.status == ShoppingListStatus.success || state.status == ShoppingListStatus.initial) &&
                    state.groupedItems.isEmpty) {
                  return const Center(
                    child: Text('Your shopping list is empty.'),
                  );
                }

                final uncheckedItems = <String, List<ShoppingListItem>>{};
                final checkedItems = <String, List<ShoppingListItem>>{};

                state.groupedItems.forEach((category, items) {
                  final unchecked = items.where((item) => !item.isChecked).toList();
                  if (unchecked.isNotEmpty) uncheckedItems[category] = unchecked;
                  final checked = items.where((item) => item.isChecked).toList();
                  if (checked.isNotEmpty) checkedItems[category] = checked;
                });

                return ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    _buildCategoryList(context, uncheckedItems),
                    if (checkedItems.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Text(
                          'Purchased Items',
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
                        ),
                      ),
                      _buildCategoryList(context, checkedItems, isCheckedList: true),
                    ]
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, Map<String, List<ShoppingListItem>> groupedItems, {bool isCheckedList = false}) {
    if (groupedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final categories = groupedItems.keys.toList()..sort();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((category) {
        final items = groupedItems[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(category, style: theme.textTheme.titleLarge),
            ),
            ...items.map((item) {
              return CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  '${_formatQuantity(item.quantity)} ${item.unit} ${item.name}',
                  style: TextStyle(
                    decoration: isCheckedList ? TextDecoration.lineThrough : TextDecoration.none,
                    color: isCheckedList ? Colors.grey : null,
                  ),
                ),
                value: item.isChecked,
                onChanged: (bool? value) {
                  context.read<ShoppingListCubit>().toggleItemStatus(item);
                },
              );
            }).toList(),
            const Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }
}