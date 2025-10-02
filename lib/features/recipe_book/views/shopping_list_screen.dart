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
      floatingActionButton:
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.orange.shade600, Colors.red.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FloatingActionButton(
          heroTag: 'fab_shopping_list',
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () async {
            _showAddManualItemDialog(context);
          },
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.orange.shade600, Colors.red.shade400],
                ),
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync, color: Colors.white),
                label: const Text('Generate from Current Week\'s Plan', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  context.read<ShoppingListCubit>().generateList();
                },
              ),
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

                final uncheckedItems = <String, List<ShoppingListItem>>{};
                final checkedItems = <String, List<ShoppingListItem>>{};

                state.groupedItems.forEach((category, items) {
                  final unchecked = items.where((item) => !item.isChecked).toList();
                  if (unchecked.isNotEmpty) uncheckedItems[category] = unchecked;
                  final checked = items.where((item) => item.isChecked).toList();
                  if (checked.isNotEmpty) checkedItems[category] = checked;
                });

                return ListView(
                  children: [
                    _buildCategoryList(context, uncheckedItems),
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
            const Divider(),
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