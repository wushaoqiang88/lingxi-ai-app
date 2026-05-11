import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/ai_module.dart';
import '../screens/brainhole_page.dart';
import '../screens/car_radio_page.dart';
import '../screens/module_detail_page.dart';

class ModuleGrid extends StatelessWidget {
  const ModuleGrid({super.key, required this.items});

  final List<AiModule> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 700
            ? 2
            : 1;
        if (columns == 1) {
          return Column(
            children: items
                .map(
                  (module) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ModuleCard(module: module),
                  ),
                )
                .toList(),
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) => ModuleCard(module: items[index]),
        );
      },
    );
  }
}

class ModuleCard extends StatelessWidget {
  const ModuleCard({super.key, required this.module});

  final AiModule module;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n.module(module);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: module.color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openModuleDetail(context, module),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                margin: const EdgeInsets.only(left: 0),
                decoration: BoxDecoration(
                  color: module.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: module.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              module.icon,
                              color: module.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  copy.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  copy.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: module.color.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        copy.tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: copy.actions
                            .map(
                              (action) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: module.color.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  action,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: module.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModuleListTile extends StatelessWidget {
  const ModuleListTile({super.key, required this.module});

  final AiModule module;

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n.module(module);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => openModuleDetail(context, module),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(module.icon, color: module.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        copy.tagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void openModuleDetail(
  BuildContext context,
  AiModule module, {
  String initialText = '',
}) {
  if (module.id == 'brainhole') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrainholePage(module: module, initialText: initialText),
      ),
    );
    return;
  }
  if (module.id == 'car_radio') {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CarRadioPage()),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          ModuleDetailPage(module: module, initialText: initialText),
    ),
  );
}
