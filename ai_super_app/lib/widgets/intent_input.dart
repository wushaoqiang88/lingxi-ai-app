import 'package:flutter/material.dart';

class IntentInput extends StatelessWidget {
  const IntentInput({
    super.key,
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                '今天想让 AI 帮你做什么？',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: '输入需求，AI 会自动分发到合适模块',
              hintStyle: TextStyle(color: Color(0xFFB0B8C9)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: loading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: const Text('智能分发'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
