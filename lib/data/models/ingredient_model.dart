// lib/data/models/ingredient_model.dart

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

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] as int?,
      recipeId: map['recipeId'] as int?,
      // Make parsing robust: handles both integers and doubles
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      name: map['name'] as String,
      preparation: map['preparation'] as String?,
    );
  }

  // --- ADD THIS METHOD ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'quantity': quantity,
      'unit': unit,
      'name': name,
      'preparation': preparation,
    };
  }

  @override
  List<Object?> get props => [id, recipeId, quantity, unit, name, preparation];
}