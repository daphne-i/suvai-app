import 'package:equatable/equatable.dart';

class ShoppingListItem extends Equatable {
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final bool isChecked;

  const ShoppingListItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isChecked = false,
  });

  ShoppingListItem copyWith({bool? isChecked}) {
    return ShoppingListItem(
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  @override
  List<Object?> get props => [name, quantity, unit, category, isChecked];
}