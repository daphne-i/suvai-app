import 'package:equatable/equatable.dart';

class Ingredient extends Equatable {
  final int? id;
  final int? recipeId;
  final double quantity;
  final String unit;
  final String name;
  final String? preparation;

  const Ingredient({
    this.id,
    this.recipeId,
    required this.quantity,
    required this.unit,
    required this.name,
    this.preparation,
  });

  @override
  List<Object?> get props => [id, recipeId, quantity, unit, name, preparation];
}