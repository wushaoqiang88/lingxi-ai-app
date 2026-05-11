import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/ai_module.dart';
import '../models/api_models.dart';
import '../services/api_client.dart';

class BrainholePage extends StatefulWidget {
  const BrainholePage({super.key, required this.module, this.initialText = ''});

  final AiModule module;
  final String initialText;

  @override
  State<BrainholePage> createState() => _BrainholePageState();
}

class _BrainholePageState extends State<BrainholePage> {
  final api = const ApiClient();
  late final TextEditingController controller;
  bool loading = false;
  ModuleRunResult? result;
  String? expandedIdea;
  String? expandedResult;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(title: Text(l10n.brainholeSpotTitle)),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const BrainholeHero(),
            const SizedBox(height: 16),
            BrainholeComposer(
              controller: controller,
              seeds: l10n.brainholeSeeds,
              loading: loading,
              onSeed: (seed) {
                controller.text = seed;
                runBrainhole();
              },
              onRun: runBrainhole,
            ),
            const SizedBox(height: 16),
            if (loading) const BrainholeLoading(),
            if (!loading && result == null) const BrainholeEmptyState(),
            if (result != null) ...[
              ...result!.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IdeaCard(
                    text: item,
                    expandedText: expandedIdea == item ? expandedResult : null,
                    expanding: expandedIdea == item && expandedResult == null,
                    onCopy: () => copyText(item),
                    onExpand: () => expandIdea(item),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> runBrainhole() async {
    final l10n = context.l10n;
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final requestText = l10n.runBrainholePrompt(text);
    setState(() {
      loading = true;
      result = null;
      expandedIdea = null;
      expandedResult = null;
    });
    try {
      final value = await api.runModule(
        moduleId: 'brainhole',
        text: requestText,
        mode: 'brainhole',
        payload: {'locale': l10n.languageCode},
      );
      setState(() => result = value);
    } catch (error) {
      setState(() {
        result = ModuleRunResult(
          source: 'fallback',
          provider: 'local',
          model: 'error',
          items: [l10n.backendMissingIdea],
          imageUrls: const [],
          files: const [],
          tips: [error.toString()],
          error: error.toString(),
        );
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> expandIdea(String idea) async {
    final l10n = context.l10n;
    setState(() {
      expandedIdea = idea;
      expandedResult = null;
    });
    try {
      final value = await api.runModule(
        moduleId: 'brainhole',
        text: l10n.expandPrompt(idea),
        mode: 'expand',
        payload: {'locale': l10n.languageCode},
      );
      if (!mounted) return;
      setState(() => expandedResult = value.items.join('\n\n'));
    } catch (error) {
      if (!mounted) return;
      setState(() => expandedResult = l10n.expandFailed(error));
    }
  }

  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.copiedIdea)));
  }
}

class BrainholeHero extends StatelessWidget {
  const BrainholeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF431407),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF431407).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -30,
            child: Icon(
              Icons.psychology_alt_rounded,
              size: 170,
              color: const Color(0xFFFFEDD5).withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.brainholeHeroTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.18,
                          color: Color(0xFFFFF7ED),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.brainholeHeroBody,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFFFFEDD5),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    HeroMetric(value: '5', label: l10n.brainholeMetricCards),
                    const SizedBox(width: 10),
                    HeroMetric(value: '1', label: l10n.brainholeMetricCall),
                    const SizedBox(width: 10),
                    HeroMetric(value: '∞', label: l10n.brainholeMetricExpand),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeroMetric extends StatelessWidget {
  const HeroMetric({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFFEDD5).withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFDE68A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFFFEDD5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrainholeComposer extends StatelessWidget {
  const BrainholeComposer({
    super.key,
    required this.controller,
    required this.seeds,
    required this.loading,
    required this.onSeed,
    required this.onRun,
  });

  final TextEditingController controller;
  final List<String> seeds;
  final bool loading;
  final ValueChanged<String> onSeed;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9A3412).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.brainholePromptTitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF431407),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.brainholeHint),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: seeds
                .map(
                  (seed) => SeedButton(
                    label: seed,
                    enabled: !loading,
                    onTap: () => onSeed(seed),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onRun,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bolt_rounded),
              label: Text(l10n.brainholeRun),
            ),
          ),
        ],
      ),
    );
  }
}

class SeedButton extends StatelessWidget {
  const SeedButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFFB923C)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.blur_on_rounded,
                size: 16,
                color: enabled
                    ? const Color(0xFFF97316)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: enabled
                      ? const Color(0xFF7C2D12)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrainholeLoading extends StatelessWidget {
  const BrainholeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: 12),
          Text(
            l10n.brainholeLoading,
            style: const TextStyle(
              color: Color(0xFF9A3412),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class BrainholeEmptyState extends StatelessWidget {
  const BrainholeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFF97316)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.brainholeEmpty,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IdeaCard extends StatelessWidget {
  const IdeaCard({
    super.key,
    required this.text,
    required this.onCopy,
    required this.onExpand,
    this.expandedText,
    this.expanding = false,
  });

  final String text;
  final VoidCallback onCopy;
  final VoidCallback onExpand;
  final String? expandedText;
  final bool expanding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = firstLine(text);
    final body = text.split('\n').skip(1).join('\n').trim();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF431407).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFF97316),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.25,
                    color: Color(0xFF431407),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body.isEmpty ? text : body,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Color(0xFF7C2D12),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(l10n.copy),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: expanding ? null : onExpand,
                        icon: expanding
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.unfold_more_rounded, size: 16),
                        label: Text(l10n.expand),
                      ),
                    ),
                  ],
                ),
                if (expandedText != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Text(
                      expandedText!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: Color(0xFF7C2D12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String firstLine(String value) {
    final lines = value
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    return lines.isEmpty ? '《未命名脑洞》' : lines.first.trim();
  }
}
