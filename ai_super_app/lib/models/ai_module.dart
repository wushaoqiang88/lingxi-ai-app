import 'package:flutter/material.dart';

class AiModule {
  const AiModule({
    required this.id,
    required this.name,
    required this.category,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.actions,
    required this.scenarios,
    required this.placeholder,
  });

  final String id;
  final String name;
  final String category;
  final String tagline;
  final IconData icon;
  final Color color;
  final List<String> actions;
  final List<String> scenarios;
  final String placeholder;
}
