import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suvai/data/repositories/shopping_list_repository.dart';
import 'package:suvai/features/shopping_list/cubit/shopping_list_cubit.dart';
import 'package:suvai/features/shopping_list/cubit/shopping_list_state.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('--- CHECKPOINT 4: ShoppingListScreen build() called. ---');
    return BlocProvider(
      create: (context) => ShoppingListCubit(
        context.read<ShoppingListRepository>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shopping List'),
        ),
        body: const _ShoppingListView(),
      ),
    );
  }
}

class _ShoppingListView extends StatelessWidget {
  const _ShoppingListView();

  @override
  Widget build(BuildContext context) {
    print('--- CHECKPOINT 5: _ShoppingListView build() called. ---');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.sync),
            label: const Text('Generate from Current Week\'s Plan'),
            onPressed: () {
              print('--- UI: Generate button tapped! ---');
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
              if (state.status == ShoppingListStatus.initial || state.groupedItems.isEmpty) {
                return const Center(child: Text('Generate a list to see your items.'));
              }

              final categories = state.groupedItems.keys.toList()..sort();

              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final items = state.groupedItems[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          category,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      ...items.map((item) {
                        return CheckboxListTile(
                          title: Text('${item.quantity} ${item.unit} ${item.name}'),
                          value: item.isChecked,
                          onChanged: (bool? value) {
                            // TODO: Connect to cubit to toggle item
                          },
                        );
                      }).toList(),
                      const Divider(),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}