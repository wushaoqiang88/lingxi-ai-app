import 'package:flutter/material.dart';

import '../data/modules.dart';
import '../l10n/app_strings.dart';
import '../widgets/module_card.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.category});

  final String category;

  Color get _categoryColor {
    switch (category) {
      case '陪伴':
        return const Color(0xFFE11D48);
      case '学习':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF059669);
    }
  }

  IconData get _categoryIcon {
    switch (category) {
      case '陪伴':
        return Icons.favorite_rounded;
      case '学习':
        return Icons.school_rounded;
      default:
        return Icons.palette_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = modules.where((item) {
      if (category == '创作') {
        return item.category == '创作' ||
            item.category == '影像' ||
            item.category == '求职';
      }
      return item.category == category;
    }).toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _categoryColor,
                  _categoryColor.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _categoryColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.categoryLabel(category),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.categorySubtitle(category),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _categoryIcon,
                  size: 48,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ModuleGrid(items: items),
        ],
      ),
    );
  }
}
