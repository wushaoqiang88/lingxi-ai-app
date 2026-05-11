import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

class HeaderBlock extends StatelessWidget {
  const HeaderBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 0,
            child: Icon(
              Icons.psychology_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.appTagline,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
