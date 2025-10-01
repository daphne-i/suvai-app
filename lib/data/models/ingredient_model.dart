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

  // --- ADD THIS FACTORY CONSTRUCTOR ---
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as int?,
      recipeId: map['recipeId'] as int?,
      quantity: map['quantity'] as double,
      unit: map['unit'] as String,
      name: map['name'] as String,
      preparation: map['preparation'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, recipeId, quantity, unit, name, preparation];
}