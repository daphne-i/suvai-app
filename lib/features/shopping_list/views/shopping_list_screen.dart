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
    // This widget now ONLY provides the cubit
    return BlocProvider(
      create: (context) => ShoppingListCubit(
        context.read<ShoppingListRepository>(),
      ),
      // The child is the widget that contains all the UI
      child: const _ShoppingListView(),
    );
  }
}

class _ShoppingListView extends StatelessWidget {
  const _ShoppingListView();

  // Helper method to show the dialog for adding a manual item
  Future<void> _showAddManualItemDialog(BuildContext context) async {
    final textController = TextEditingController();
    // This context is now correct (it's a descendant of the BlocProvider)
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
    // The entire Scaffold is now inside this widget
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // This context is also correct now
          _showAddManualItemDialog(context);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Generate from Current Week\'s Plan'),
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
                if (state.status == ShoppingListStatus.success && state.groupedItems.isEmpty) {
                  return const Center(
                    child: Text('No ingredients needed for this week\'s plan!'),
                  );
                }
                if (state.status == ShoppingListStatus.initial) {
                  return const Center(
                    child: Text('Generate a list to see your items.'),
                  );
                }

                // Split items into unchecked and checked for rendering
                final uncheckedItems = <String, List<ShoppingListItem>>{};
                final checkedItems = <String, List<ShoppingListItem>>{};

                state.groupedItems.forEach((category, items) {
                  final unchecked = items.where((item) => !item.isChecked).toList();
                  if (unchecked.isNotEmpty) {
                    uncheckedItems[category] = unchecked;
                  }
                  final checked = items.where((item) => item.isChecked).toList();
                  if (checked.isNotEmpty) {
                    checkedItems[category] = checked;
                  }
                });

                return ListView(
                  children: [
                    // Render the list of items to buy
                    _buildCategoryList(context, uncheckedItems),

                    // Render the list of purchased items
                    if (checkedItems.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Text(
                          'Purchased Items',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
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

  // Helper method to render a list of items, grouped by category
  Widget _buildCategoryList(BuildContext context, Map<String, List<ShoppingListItem>> groupedItems, {bool isCheckedList = false}) {
    if (groupedItems.isEmpty && !isCheckedList) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("You've got everything!")),
      );
    }
    if (groupedItems.isEmpty && isCheckedList) {
      return const SizedBox.shrink();
    }

    final categories = groupedItems.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categories.map((category) {
        final items = groupedItems[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(category, style: Theme.of(context).textTheme.titleLarge),
            ),
            ...items.map((item) {
              return CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  // Use a helper to format the quantity nicely
                  '${_formatQuantity(item.quantity)} ${item.unit} ${item.name}',
                  style: TextStyle(
                    decoration: isCheckedList ? TextDecoration.lineThrough : TextDecoration.none,
                    color: isCheckedList ? Colors.grey : null,
                  ),
                ),
                value: item.isChecked,
                onChanged: (bool? value) {
                  // Connect to the cubit to toggle the item's status
                  context.read<ShoppingListCubit>().toggleItemStatus(item);
                },
              );
            }).toList(),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }

  // Helper to avoid showing .0 for whole numbers
  String _formatQuantity(double quantity) {
    if (quantity == quantity.toInt()) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }
}