import 'package:flutter/material.dart';

class Plate {
  const Plate({
    required this.id,
    required this.title,
    this.color = Colors.orange,
    this.mealIds = const [],
  });

  final String id;
  final String title;
  final Color color;
  final List<String> mealIds;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color': color.toARGB32(),
      'mealIds': mealIds,
    };
  }

  factory Plate.fromMap(Map<String, dynamic> map) {
    return Plate(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      color: Color(map['color'] ?? Colors.orange.toARGB32()),
      mealIds: List<String>.from(map['mealIds'] ?? []),
    );
  }

  Plate copyWith({
    String? id,
    String? title,
    Color? color,
    List<String>? mealIds,
  }) {
    return Plate(
      id: id ?? this.id,
      title: title ?? this.title,
      color: color ?? this.color,
      mealIds: mealIds ?? this.mealIds,
    );
  }
}
