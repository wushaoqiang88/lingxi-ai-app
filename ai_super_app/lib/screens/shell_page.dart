import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'category_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      const HomePage(),
      const CategoryPage(category: '陪伴'),
      const CategoryPage(category: '创作'),
      const CategoryPage(category: '学习'),
      const ProfilePage(),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l10n.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.favorite_outline),
              selectedIcon: const Icon(Icons.favorite_rounded),
              label: l10n.companion,
            ),
            NavigationDestination(
              icon: const Icon(Icons.palette_outlined),
              selectedIcon: const Icon(Icons.palette_rounded),
              label: l10n.creation,
            ),
            NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              selectedIcon: const Icon(Icons.school_rounded),
              label: l10n.study,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person_rounded),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}
