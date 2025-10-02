// lib/data/models/instruction_model.dart

import 'package:equatable/equatable.dart';

class Instruction extends Equatable {
  final String description;
  final int? durationInMinutes;

  const Instruction({
    required this.description,
    this.durationInMinutes,
  });

  @override
  List<Object?> get props => [description, durationInMinutes];

  // For JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'durationInMinutes': durationInMinutes,
    };
  }

  // For JSON deserialization
  factory Instruction.fromJson(Map<String, dynamic> json) {
    return Instruction(
      description: json['description'] as String,
      durationInMinutes: json['durationInMinutes'] as int?,
    );
  }
}

