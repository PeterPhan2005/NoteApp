import 'package:flutter/material.dart';

class Category {
  String id;
  String name;
  String color;
  String icon;
  DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
      'icon': icon,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] ?? '',
      color: map['color'] ?? 'blue',
      icon: map['icon'] ?? 'folder',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }

  Color get colorValue {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      case 'pink':
        return Colors.pink;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }

  IconData get iconData {
    switch (icon) {
      case 'work':
        return Icons.work;
      case 'personal':
        return Icons.person;
      case 'study':
        return Icons.school;
      case 'health':
        return Icons.health_and_safety;
      case 'travel':
        return Icons.flight;
      case 'shopping':
        return Icons.shopping_cart;
      case 'home':
        return Icons.home;
      case 'money':
        return Icons.attach_money;
      default:
        return Icons.folder;
    }
  }
}
