import 'package:equatable/equatable.dart';
import 'package:suvai/data/models/shopping_list_item_model.dart';

enum ShoppingListStatus { initial, loading, success, failure }

class ShoppingListState extends Equatable {
  final ShoppingListStatus status;
  // The list is stored as a map, with category names as keys
  final Map<String, List<ShoppingListItem>> groupedItems;
  final String errorMessage;

  const ShoppingListState({
    this.status = ShoppingListStatus.initial,
    this.groupedItems = const {},
    this.errorMessage = '',
  });

  @override
  List<Object> get props => [status, groupedItems, errorMessage];

  ShoppingListState copyWith({
    ShoppingListStatus? status,
    Map<String, List<ShoppingListItem>>? groupedItems,
    String? errorMessage,
  }) {
    return ShoppingListState(
      status: status ?? this.status,
      groupedItems: groupedItems ?? this.groupedItems,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}