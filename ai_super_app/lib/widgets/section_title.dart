import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            action,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
