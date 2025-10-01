import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:suvai/data/repositories/shopping_list_repository.dart';
import 'shopping_list_state.dart';

class ShoppingListCubit extends Cubit<ShoppingListState> {
  final ShoppingListRepository _shoppingListRepository;

  ShoppingListCubit(this._shoppingListRepository) : super(const ShoppingListState());

  Future<void> generateList() async {
    print('CUBIT: generateList called.');
    emit(state.copyWith(status: ShoppingListStatus.loading));
    try {
      // For now, we generate for the week starting today
      final items = await _shoppingListRepository.generateList(DateTime.now());
      print('CUBIT: Received ${items.length} items from repository.');

      // Group the flat list by category
      final grouped = groupBy(items, (item) => item.category);
      print('CUBIT: Grouped into ${grouped.keys.length} categories.');

      emit(state.copyWith(status: ShoppingListStatus.success, groupedItems: grouped));
    } catch (e) {
      print('CUBIT: ERROR - $e');
      emit(state.copyWith(status: ShoppingListStatus.failure, errorMessage: e.toString()));
    }
  }
}