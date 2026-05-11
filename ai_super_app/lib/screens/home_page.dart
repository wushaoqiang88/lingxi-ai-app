import 'package:flutter/material.dart';

import '../data/modules.dart';
import '../l10n/app_strings.dart';
import '../models/ai_module.dart';
import '../widgets/header_block.dart';
import '../widgets/module_card.dart';
import '../widgets/section_title.dart';
import 'car_radio_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brainhole = moduleById('brainhole');
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const HeaderBlock(),
          const SizedBox(height: 20),
          BrainholeSpotlight(module: brainhole),
          const SizedBox(height: 14),
          const CarRadioEntry(),
          const SizedBox(height: 20),
          SectionTitle(
            title: l10n.frequent,
            action: l10n.modulesConnected(modules.length),
          ),
          const SizedBox(height: 10),
          ModuleGrid(
            items: modules
                .where((module) => module.id != 'brainhole')
                .take(6)
                .toList(),
          ),
        ],
      ),
    );
  }
}

class BrainholeSpotlight extends StatelessWidget {
  const BrainholeSpotlight({super.key, required this.module});

  final AiModule module;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9A3412).withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openModuleDetail(context, module),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -18,
                child: Icon(
                  Icons.lightbulb_circle_outlined,
                  size: 136,
                  color: const Color(0xFFF97316).withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                right: 22,
                bottom: 22,
                child: Icon(
                  Icons.auto_awesome,
                  size: 24,
                  color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFF97316,
                                ).withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.psychology_alt_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.brainholeSpotTitle,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF431407),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.brainholeSpotSubtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9A3412),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.brainholeSpotBody,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF7C2D12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        BrainholeBadge(text: l10n.brainholeBadge1),
                        BrainholeBadge(text: l10n.brainholeBadge2),
                        BrainholeBadge(text: l10n.brainholeBadge3),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.brainholeTodaySeed,
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(
                                0xFF0F766E,
                              ).withValues(alpha: 0.95),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrainholeBadge extends StatelessWidget {
  const BrainholeBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF9A3412),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class CarRadioEntry extends StatelessWidget {
  const CarRadioEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CarRadioPage()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.radio_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.text('灵犀电台', 'Lingxi Radio'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.text(
                          '上车一句话，私人 AI 音频陪你通勤',
                          'One tap, your personal AI radio for the road',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.3), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
