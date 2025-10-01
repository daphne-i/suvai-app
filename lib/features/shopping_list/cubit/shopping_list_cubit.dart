import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:suvai/data/models/shopping_list_item_model.dart';
import 'package:suvai/data/repositories/shopping_list_repository.dart';
import 'shopping_list_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListCubit extends Cubit<ShoppingListState> {
  final ShoppingListRepository _shoppingListRepository;

  ShoppingListCubit(this._shoppingListRepository)
      : super(const ShoppingListState());

  Future<void> generateList() async {
    emit(state.copyWith(status: ShoppingListStatus.loading));
    try {
      // For now, we generate for the week starting today
      final items = await _shoppingListRepository.generateList(DateTime.now());
      // Group the flat list by category
      final grouped = groupBy(items, (item) => item.category);


      emit(state.copyWith(
          status: ShoppingListStatus.success, groupedItems: grouped));
    } catch (e) {
      emit(state.copyWith(
          status: ShoppingListStatus.failure, errorMessage: e.toString()));
    }
  }

  void toggleItemStatus(ShoppingListItem itemToToggle) async { // <-- Make it async
    // (The logic to create newGroupedItems is the same)
    final newGroupedItems = state.groupedItems.map(
          (key, value) => MapEntry(key, List<ShoppingListItem>.from(value)),
    );
    final categoryItems = newGroupedItems[itemToToggle.category];
    if (categoryItems == null) return;
    final itemIndex = categoryItems.indexWhere((item) => item == itemToToggle);
    if (itemIndex == -1) return;

    final updatedItem = categoryItems[itemIndex].copyWith(
      isChecked: !categoryItems[itemIndex].isChecked,
    );
    categoryItems[itemIndex] = updatedItem;

    // --- 3. ADD THIS SAVE LOGIC ---
    // Save the new checked status to local storage
    final prefs = await SharedPreferences.getInstance();
    final itemKey = '${updatedItem.name.trim().toLowerCase()}_${updatedItem.unit.trim().toLowerCase()}';
    await prefs.setBool(itemKey, updatedItem.isChecked);

    // Emit the new state to update the UI
    emit(state.copyWith(groupedItems: newGroupedItems));
  }

  void addManualItem(String name) {
    if (name.trim().isEmpty) return;

    final newItem = ShoppingListItem(
      name: name.trim(),
      quantity: 1,
      unit: 'item',
      category: 'Manual Additions',
      isChecked: false,
    );

    // Create a deep copy of the map to ensure immutability
    final newGroupedItems = state.groupedItems.map(
          (key, value) => MapEntry(key, List<ShoppingListItem>.from(value)),
    );

    // Add the new item to the 'Manual Additions' category
    if (newGroupedItems.containsKey('Manual Additions')) {
      newGroupedItems['Manual Additions']!.add(newItem);
    } else {
      newGroupedItems['Manual Additions'] = [newItem];
    }

    emit(state.copyWith(groupedItems: newGroupedItems));
  }

  // --- ADD THIS NEW METHOD ---
  void clearList() async {
    final prefs = await SharedPreferences.getInstance();

    // Iterate through all items in the current state and remove their saved checked status
    for (var category in state.groupedItems.values) {
      for (var item in category) {
        final itemKey = '${item.name.trim().toLowerCase()}_${item.unit.trim().toLowerCase()}';
        if (await prefs.containsKey(itemKey)) {
          await prefs.remove(itemKey);
        }
      }
    }
    // Reset the state to its initial, empty state
    emit(const ShoppingListState());
  }

}

