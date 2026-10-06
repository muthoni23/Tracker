import 'package:flutter/material.dart';

class Course {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const Course({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  factory Course.fromMap(String id, Map<String, dynamic> map) {
    return Course(
      id: id,
      name: map['name'] ?? '',
      color: Color(map['color'] ?? 0xFF3B5BDB),
      icon: IconData(map['iconCode'] ?? Icons.book.codePoint,
          fontFamily: 'MaterialIcons'),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'color': color.value,
        'iconCode': icon.codePoint,
      };
}

/// Fixed icon choices offered in the "Add course" dialog
/// (IconData.codePoint round-trips through Firestore fine for these
/// constant, tree-shaken-safe icons).
const List<IconData> kCourseIconChoices = [
  Icons.code,
  Icons.public,
  Icons.storage,
  Icons.functions,
  Icons.science_outlined,
  Icons.language,
  Icons.brush_outlined,
  Icons.calculate_outlined,
  Icons.menu_book_outlined,
  Icons.biotech_outlined,
];
