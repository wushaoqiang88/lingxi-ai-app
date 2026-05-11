import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/app_strings.dart';
import '../services/api_client.dart';

/// 频道定义
class RadioChannel {
  const RadioChannel({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.defaultPromptZh,
    required this.defaultPromptEn,
  });

  final String id;
  final String nameZh;
  final String nameEn;
  final IconData icon;
  final Color color;
  final String defaultPromptZh;
  final String defaultPromptEn;

  String name(bool isEn) => isEn ? nameEn : nameZh;
  String defaultPrompt(bool isEn) => isEn ? defaultPromptEn : defaultPromptZh;
}

const _channels = [
  RadioChannel(
    id: 'commute',
    nameZh: '通勤播报',
    nameEn: 'Commute Brief',
    icon: Icons.wb_sunny_outlined,
    color: Color(0xFFF59E0B),
    defaultPromptZh: '给我来段早间通勤播报',
    defaultPromptEn: 'Give me a morning commute briefing',
  ),
  RadioChannel(
    id: 'mood',
    nameZh: '情绪陪伴',
    nameEn: 'Mood Radio',
    icon: Icons.spa_outlined,
    color: Color(0xFFEC4899),
    defaultPromptZh: '我有点累，陪我放松一下',
    defaultPromptEn: 'I feel tired, help me relax',
  ),
  RadioChannel(
    id: 'english',
    nameZh: '英语听力',
    nameEn: 'English Micro',
    icon: Icons.translate_outlined,
    color: Color(0xFF3B82F6),
    defaultPromptZh: '来一段日常英语微课',
    defaultPromptEn: 'Give me a daily English micro lesson',
  ),
  RadioChannel(
    id: 'story',
    nameZh: '脑洞故事',
    nameEn: 'Idea Story',
    icon: Icons.auto_stories_outlined,
    color: Color(0xFF8B5CF6),
    defaultPromptZh: '讲一个脑洞小故事',
    defaultPromptEn: 'Tell me a creative short story',
  ),
];

class CarRadioPage extends StatefulWidget {
  const CarRadioPage({super.key});

  @override
  State<CarRadioPage> createState() => _CarRadioPageState();
}

class _CarRadioPageState extends State<CarRadioPage>
    with SingleTickerProviderStateMixin {
  final api = const ApiClient();
  final _audioPlayer = AudioPlayer();
  int _currentChannel = 0;
  bool _loading = false;
  bool _playing = false;
  String? _content;
  String? _error;
  late AnimationController _pulseController;

  RadioChannel get channel => _channels[_currentChannel];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _generate([String? customText]) async {
    setState(() {
      _loading = true;
      _playing = false;
      _content = null;
      _error = null;
    });
    await _audioPlayer.stop();
    final isEn = context.l10n.isEn;
    final text = customText ?? channel.defaultPrompt(isEn);
    try {
      final result = await api.runModule(
        moduleId: 'car_radio',
        text: text,
        payload: {
          'channel': channel.id,
          if (isEn) 'locale': 'en',
        },
      );
      if (!mounted) return;
      final content = result.items.join('\n\n');
      setState(() {
        _content = content.isNotEmpty ? content : null;
        _error = result.error;
        _loading = false;
      });
      // Auto-play audio if available
      if (result.hasAudio) {
        await _playAudio(result.audioBase64, result.audioFormat);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _playAudio(String audioBase64, String format) async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playAndRecord,
            options: const {AVAudioSessionOptions.defaultToSpeaker},
          ),
        ),
      );
      final ext = format.isNotEmpty ? format : 'wav';
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/radio_$ts.$ext';
      final bytes = base64Decode(audioBase64);
      await File(path).writeAsBytes(bytes, flush: true);
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(DeviceFileSource(path), volume: 1.0);
      if (mounted) setState(() => _playing = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e'), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  void _togglePlayPause() async {
    if (_playing) {
      await _audioPlayer.pause();
      setState(() => _playing = false);
    } else {
      await _audioPlayer.resume();
      setState(() => _playing = true);
    }
  }

  void _switchChannel(int index) {
    if (index == _currentChannel) return;
    HapticFeedback.lightImpact();
    setState(() {
      _currentChannel = index;
      _content = null;
      _error = null;
    });
  }

  void _nextChannel() {
    _switchChannel((_currentChannel + 1) % _channels.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEn = l10n.isEn;
    final mq = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    l10n.text('灵犀电台', 'Lingxi Radio'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // balance back button
                ],
              ),
            ),

            // ── Channel selector ──
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _channels.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final ch = _channels[i];
                  final selected = i == _currentChannel;
                  return GestureDetector(
                    onTap: () => _switchChannel(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 80,
                      decoration: BoxDecoration(
                        color: selected
                            ? ch.color.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: selected
                            ? Border.all(color: ch.color, width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(ch.icon,
                              color: selected ? ch.color : Colors.white38,
                              size: 26),
                          const SizedBox(height: 6),
                          Text(
                            ch.name(isEn),
                            style: TextStyle(
                              color: selected ? ch.color : Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Content area ──
            Expanded(
              child: _loading
                  ? _buildLoadingView(isEn)
                  : _content != null
                      ? _buildContentView()
                      : _buildIdleView(isEn),
            ),

            // ── Bottom controls ──
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, mq.padding.bottom + 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Next channel / Regenerate
                  _content != null && !_loading
                      ? _ControlButton(
                          icon: Icons.refresh_rounded,
                          label: l10n.text('换一段', 'New'),
                          onTap: () => _generate(),
                        )
                      : _ControlButton(
                          icon: Icons.skip_next_rounded,
                          label: l10n.text('换台', 'Next'),
                          onTap: _loading ? null : _nextChannel,
                        ),
                  // Play / Pause / Generate
                  _content != null && !_loading
                      ? _PlayButton(
                          loading: false,
                          playing: _playing,
                          color: channel.color,
                          pulseController: _pulseController,
                          onTap: _togglePlayPause,
                        )
                      : _PlayButton(
                          loading: _loading,
                          playing: false,
                          color: channel.color,
                          pulseController: _pulseController,
                          onTap: _loading ? null : () => _generate(),
                        ),
                  // Copy
                  _ControlButton(
                    icon: Icons.copy_rounded,
                    label: l10n.text('复制', 'Copy'),
                    onTap: _content != null
                        ? () {
                            Clipboard.setData(
                                ClipboardData(text: _content!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.text('已复制', 'Copied')),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleView(bool isEn) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(channel.icon,
                size: 72, color: channel.color.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text(
              channel.name(isEn),
              style: TextStyle(
                color: channel.color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isEn
                  ? 'Tap the play button to generate your personal radio segment'
                  : '点击播放按钮，生成你的私人电台内容',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView(bool isEn) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.4 + _pulseController.value * 0.6,
                child: Icon(Icons.graphic_eq_rounded,
                    size: 64, color: channel.color),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            isEn ? 'Generating your radio...' : '正在为你生成电台内容...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(channel.icon, color: channel.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  channel.name(context.l10n.isEn),
                  style: TextStyle(
                    color: channel.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _content!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.8,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.amber.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Large play button ──
class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.loading,
    required this.color,
    required this.pulseController,
    required this.onTap,
    this.playing = false,
  });

  final bool loading;
  final bool playing;
  final Color color;
  final AnimationController pulseController;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = loading
        ? null
        : playing
            ? Icons.pause_rounded
            : Icons.play_arrow_rounded;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Icon(icon, color: Colors.white, size: 40),
      ),
    );
  }
}

// ── Small control button ──
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: enabled ? 0.1 : 0.04),
            ),
            child: Icon(icon,
                color: Colors.white
                    .withValues(alpha: enabled ? 0.8 : 0.25),
                size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white
                  .withValues(alpha: enabled ? 0.6 : 0.2),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
