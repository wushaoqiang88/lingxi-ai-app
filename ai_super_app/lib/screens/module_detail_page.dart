import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../models/ai_module.dart';
import '../models/api_models.dart';
import '../services/api_client.dart';
import '../widgets/result_panel.dart';

class ModuleDetailPage extends StatefulWidget {
  const ModuleDetailPage({
    super.key,
    required this.module,
    this.initialText = '',
  });

  final AiModule module;
  final String initialText;

  @override
  State<ModuleDetailPage> createState() => _ModuleDetailPageState();
}

class _ModuleDetailPageState extends State<ModuleDetailPage> {
  final api = const ApiClient();
  final picker = ImagePicker();
  final recorder = AudioRecorder();
  final audioPlayer = AudioPlayer();
  final resultKey = GlobalKey();
  late final TextEditingController controller;
  bool loading = false;
  bool recording = false;
  ModuleRunResult? result;
  Uint8List? generatedImageBytes;
  String? generatedImageLabel;
  String? attachmentLabel;
  Map<String, dynamic> attachmentPayload = const {};
  List<Map<String, String>> conversationHistory = const [];

  bool get hasConversationMemory =>
      {'companion', 'avatar', 'treehole'}.contains(widget.module.id);

  String get memoryKey => 'conversation_history_${widget.module.id}';

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
    loadConversationHistory().then((_) {
      if (widget.initialText.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => runModule());
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    recorder.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final copy = context.l10n.module(module);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(copy.name)),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Container(
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
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          module.color,
                          module.color.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: module.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                module.icon,
                                color: module.color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    copy.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    copy.category,
                                    style: TextStyle(
                                      color: module.color.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          copy.tagline,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.l10n.text('核心场景', 'Core Scenarios'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: copy.scenarios
                              .map(
                                (item) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.l10n.text('快捷能力', 'Quick Actions'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: copy.actions
                              .map(
                                (action) => Material(
                                  color: module.color.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      controller.text = context.l10n.text(
                                        '请使用"$action"能力，围绕：${module.placeholder}',
                                        'Use "$action" around this request: ${copy.placeholder}',
                                      );
                                      runModule();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.flash_on,
                                            color: module.color,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            action,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: module.color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.text('输入需求', 'Your Request'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    minLines: 4,
                    maxLines: 7,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: copy.placeholder,
                      hintStyle: const TextStyle(color: Color(0xFFB0B8C9)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InputTools(
                    moduleId: widget.module.id,
                    onCamera: pickCamera,
                    onGallery: pickGallery,
                    onFile: pickFile,
                  ),
                  if ({'image_fix', 'dressup'}.contains(widget.module.id)) ...[
                    const SizedBox(height: 10),
                    CapabilityNotice(moduleId: widget.module.id),
                  ],
                  if (attachmentLabel != null) ...[
                    const SizedBox(height: 10),
                    AttachmentChip(
                      label: attachmentLabel!,
                      onDeleted: clearAttachment,
                    ),
                  ],
                  if (hasConversationMemory) ...[
                    const SizedBox(height: 10),
                    MemoryStatusChip(
                      rounds: conversationHistory.length ~/ 2,
                      onClear: clearConversationHistory,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (widget.module.id == 'companion') ...[
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: recording
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: recording ? const Color(0xFFFEF2F2) : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: loading ? null : toggleVoiceChat,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    recording
                                        ? Icons.stop_circle_rounded
                                        : Icons.mic_none_rounded,
                                    color: recording
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    recording
                                        ? context.l10n.text(
                                            '停止录音并发送',
                                            'Stop and Send',
                                          )
                                        : context.l10n.text(
                                            '语音聊天',
                                            'Voice Chat',
                                          ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: recording
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            module.color,
                            module.color.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: module.color.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: loading ? null : runModule,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        icon: loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.play_arrow_rounded, size: 20),
                        label: Text(context.l10n.text('运行模块', 'Run Module')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ResultPanel(
              key: resultKey,
              result: result,
              loading: loading,
              generatedImageBytes: generatedImageBytes,
              generatedImageLabel: generatedImageLabel,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> runModule() async {
    final inputText = controller.text.trim();
    final payload = <String, dynamic>{
      ...attachmentPayload,
      'locale': context.l10n.languageCode,
    };
    if (hasConversationMemory && conversationHistory.isNotEmpty) {
      payload['conversation_history'] = conversationHistory;
    }
    setState(() {
      loading = true;
      result = null;
      generatedImageBytes = null;
      generatedImageLabel = null;
    });
    try {
      final value = await api.runModule(
        moduleId: widget.module.id,
        text: inputText,
        mode: 'prototype',
        payload: payload,
      );
      if (hasConversationMemory && value.isAi && inputText.isNotEmpty) {
        await appendConversationTurn(inputText, value.items.join('\n\n'));
      }
      setState(() {
        result = value;
        generatedImageBytes = null;
        generatedImageLabel = null;
      });
      scrollToResult();
    } catch (error) {
      setState(() {
        result = ModuleRunResult(
          source: 'fallback',
          provider: 'local',
          model: 'error',
          items: [
            '后端暂未连接。请启动 FastAPI：uvicorn app.main:app --reload --port 8000',
          ],
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

  Future<void> toggleVoiceChat() async {
    if (recording) {
      await stopVoiceChat();
    } else {
      await startVoiceChat();
    }
  }

  Future<void> startVoiceChat() async {
    if (!await recorder.hasPermission()) {
      setState(() {
        result = const ModuleRunResult(
          source: 'fallback',
          provider: 'local',
          model: 'permission',
          items: ['需要开启麦克风权限后才能语音聊天。'],
          imageUrls: [],
          files: [],
          tips: ['请在系统设置中允许麦克风权限'],
          error: 'microphone_permission_denied',
        );
      });
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/companion_voice.wav';
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
      path: path,
    );
    if (mounted) setState(() => recording = true);
  }

  Future<void> stopVoiceChat() async {
    final path = await recorder.stop();
    if (mounted) setState(() => recording = false);
    if (path == null) return;
    final bytes = await XFile(path).readAsBytes();
    final payload = <String, dynamic>{};
    if (conversationHistory.isNotEmpty) {
      payload['conversation_history'] = conversationHistory;
    }
    setState(() {
      loading = true;
      result = null;
      generatedImageBytes = null;
      generatedImageLabel = null;
    });
    try {
      final value = await api.runCompanionVoice(
        audioBase64: base64Encode(bytes),
        format: 'wav',
        payload: payload,
      );
      if (value.isAi) {
        await appendConversationTurn('语音消息', value.items.join('\n\n'));
      }
      setState(() => result = value);
      if (value.hasAudio) {
        await playAssistantAudio(value.audioBase64, value.audioFormat);
      }
      scrollToResult();
    } catch (error) {
      setState(() {
        result = ModuleRunResult(
          source: 'fallback',
          provider: 'local',
          model: 'voice_error',
          items: ['语音聊天暂时失败，请稍后再试。'],
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

  Future<void> playAssistantAudio(String audioBase64, String format) async {
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
      final path = '${dir.path}/companion_reply_$ts.$ext';
      final bytes = base64Decode(audioBase64);
      await File(path).writeAsBytes(bytes, flush: true);
      await audioPlayer.stop();
      await audioPlayer.setReleaseMode(ReleaseMode.stop);
      await audioPlayer.play(DeviceFileSource(path), volume: 1.0);
    } catch (e) {
      // 显示播放失败提示，方便排查
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('语音播放失败: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> loadConversationHistory() async {
    if (!hasConversationMemory) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(memoryKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw) as List<dynamic>;
    final history = decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => {
            'role': item['role']?.toString() ?? '',
            'content': item['content']?.toString() ?? '',
          },
        )
        .where(
          (item) => item['role']!.isNotEmpty && item['content']!.isNotEmpty,
        )
        .toList();
    if (mounted) setState(() => conversationHistory = history);
  }

  Future<void> appendConversationTurn(
    String userText,
    String assistantText,
  ) async {
    final nextHistory = [
      ...conversationHistory,
      {'role': 'user', 'content': userText},
      {'role': 'assistant', 'content': assistantText},
    ];
    final trimmed = nextHistory.length > 40
        ? nextHistory.sublist(nextHistory.length - 40)
        : nextHistory;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(memoryKey, jsonEncode(trimmed));
    if (mounted) setState(() => conversationHistory = trimmed);
  }

  Future<void> clearConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(memoryKey);
    if (mounted) setState(() => conversationHistory = const []);
  }

  void scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = resultKey.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    });
  }

  Future<void> pickCamera() async {
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 72,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setAttachment('拍照：${image.name}', {
      'attachment_type': 'image',
      'source': 'camera',
      'name': image.name,
      'mime_type': image.mimeType ?? 'image/jpeg',
      'base64': base64Encode(bytes),
      'size': bytes.length,
    });
  }

  Future<void> pickGallery() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    setAttachment('相册：${image.name}', {
      'attachment_type': 'image',
      'source': 'gallery',
      'name': image.name,
      'mime_type': image.mimeType ?? 'image/jpeg',
      'base64': base64Encode(bytes),
      'size': bytes.length,
    });
  }

  Future<void> pickFile() async {
    final result = await FilePicker.pickFiles(withData: true);
    final file = result?.files.single;
    if (file == null) return;
    final bytes = file.bytes;
    final textPreview = bytes == null
        ? ''
        : utf8.decode(bytes, allowMalformed: true);
    setAttachment('文件：${file.name}', {
      'attachment_type': 'file',
      'name': file.name,
      'size': file.size,
      'extension': file.extension,
      'text': textPreview.length > 12000
          ? textPreview.substring(0, 12000)
          : textPreview,
    });
  }

  void setAttachment(String label, Map<String, dynamic> payload) {
    setState(() {
      attachmentLabel = label;
      attachmentPayload = payload;
    });
  }

  void clearAttachment() {
    setState(() {
      attachmentLabel = null;
      attachmentPayload = const {};
    });
  }
}

class InputTools extends StatelessWidget {
  const InputTools({
    super.key,
    required this.moduleId,
    required this.onCamera,
    required this.onGallery,
    required this.onFile,
  });

  final String moduleId;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    final imageModules = {'image_fix', 'dressup', 'study'};
    final fileModules = {
      'writing',
      'office_doc',
      'study',
      'knowledge',
      'resume',
      'career',
      'companion',
      'avatar',
      'treehole',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (imageModules.contains(moduleId))
          OutlinedButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('拍照'),
          ),
        if (imageModules.contains(moduleId))
          OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('相册'),
          ),
        if (fileModules.contains(moduleId))
          OutlinedButton.icon(
            onPressed: onFile,
            icon: const Icon(Icons.attach_file),
            label: const Text('导入文件'),
          ),
      ],
    );
  }
}

class AttachmentChip extends StatelessWidget {
  const AttachmentChip({
    super.key,
    required this.label,
    required this.onDeleted,
  });

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: const Icon(Icons.description_outlined, size: 18),
      label: Text(label),
      onDeleted: onDeleted,
    );
  }
}

class MemoryStatusChip extends StatelessWidget {
  const MemoryStatusChip({
    super.key,
    required this.rounds,
    required this.onClear,
  });

  final int rounds;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: const Icon(Icons.history, size: 18),
      label: Text('短期记忆：$rounds/20 轮'),
      onDeleted: rounds > 0 ? onClear : null,
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }
}

class CapabilityNotice extends StatelessWidget {
  const CapabilityNotice({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final text = moduleId == 'dressup'
        ? '已接入真实图像编辑服务：上传人像后会生成 AI 换装图，耗时可能较长。'
        : '已接入真实图像编辑服务：上传图片后会生成 AI 修图结果，耗时可能较长。';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFF92400E))),
          ),
        ],
      ),
    );
  }
}
