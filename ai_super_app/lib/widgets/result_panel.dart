import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:screenshot/screenshot.dart';

import '../l10n/app_strings.dart';
import '../models/api_models.dart';
import '../services/api_client.dart';
import '../services/local_exporter.dart';

class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.result,
    required this.loading,
    this.generatedImageBytes,
    this.generatedImageLabel,
  });

  final ModuleRunResult? result;
  final bool loading;
  final Uint8List? generatedImageBytes;
  final String? generatedImageLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.text('AI 结果', 'AI Result'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              if (result != null) SourceBadge(result: result!),
            ],
          ),
          const SizedBox(height: 12),
          if (loading)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: const Color(0xFFF1F5F9),
                color: theme.colorScheme.primary,
                minHeight: 3,
              ),
            ),
          if (!loading && result == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 36,
                    color: const Color(0xFFCBD5E1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.text(
                      '运行后会在这里展示模块输出',
                      'Module output will appear here after running',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          if (result != null) ...[
            if (generatedImageBytes != null) ...[
              GeneratedImageResult(
                bytes: generatedImageBytes!,
                label: generatedImageLabel ?? l10n.text('图片结果', 'Image Result'),
              ),
              const SizedBox(height: 10),
            ],
            for (final imageUrl in result!.imageUrls) ...[
              GeneratedNetworkImageResult(url: imageUrl),
              const SizedBox(height: 10),
            ],
            for (final file in result!.files) ...[
              DownloadableFileResult(file: file),
              const SizedBox(height: 10),
            ],
            ...result!.items.map((item) => ResultItem(text: item)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        copyText(context, result!.items.join('\n\n')),
                    icon: const Icon(Icons.copy_all_outlined, size: 16),
                    label: Text(l10n.copy),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => saveResultText(context, result!),
                    icon: const Icon(Icons.save_alt_outlined, size: 16),
                    label: Text(l10n.text('保存', 'Save')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => showShareCard(context, result!),
                    icon: const Icon(Icons.ios_share_outlined, size: 16),
                    label: Text(l10n.text('分享', 'Share')),
                  ),
                ),
              ],
            ),
            if (result!.tips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: result!.tips
                    .map(
                      (tip) => Chip(
                        label: Text(tip),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class GeneratedImageResult extends StatelessWidget {
  const GeneratedImageResult({
    super.key,
    required this.bytes,
    required this.label,
  });

  final Uint8List bytes;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () =>
                  saveImageBytes(context, bytes, imageFileName(label)),
              icon: const Icon(Icons.download_outlined),
              label: Text(context.l10n.text('保存图片', 'Save Image')),
            ),
          ),
        ],
      ),
    );
  }
}

class GeneratedNetworkImageResult extends StatelessWidget {
  const GeneratedNetworkImageResult({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.text('真实 AI 图片结果', 'Real AI Image Result'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: double.infinity,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Padding(
                  padding: EdgeInsets.all(18),
                  child: LinearProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    context.l10n.text(
                      '图片加载失败，请重新生成',
                      'Image failed to load. Please regenerate.',
                    ),
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => saveImageUrl(context, url),
              icon: const Icon(Icons.download_outlined),
              label: Text(context.l10n.text('保存图片', 'Save Image')),
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadableFileResult extends StatefulWidget {
  const DownloadableFileResult({super.key, required this.file});

  final DocFile file;

  @override
  State<DownloadableFileResult> createState() => _DownloadableFileResultState();
}

class _DownloadableFileResultState extends State<DownloadableFileResult> {
  bool _downloading = false;

  IconData get _icon {
    switch (widget.file.type) {
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'xlsx':
        return Icons.table_chart_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color get _color {
    switch (widget.file.type) {
      case 'pptx':
        return const Color(0xFFD97706);
      case 'pdf':
        return const Color(0xFFDC2626);
      case 'xlsx':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String get _typeLabel {
    switch (widget.file.type) {
      case 'pptx':
        return context.l10n.text('PowerPoint 演示文稿', 'PowerPoint Presentation');
      case 'pdf':
        return context.l10n.text('PDF 文档', 'PDF Document');
      case 'xlsx':
        return context.l10n.text('Excel 表格', 'Excel Spreadsheet');
      default:
        return context.l10n.text('文件', 'File');
    }
  }

  String get _absoluteUrl => Uri.encodeFull('$apiBaseUrl${widget.file.url}');

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _absoluteUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.text('下载链接已复制', 'Download link copied')),
      ),
    );
  }

  Future<void> _download() async {
    final l10n = context.l10n;
    setState(() => _downloading = true);
    try {
      final url = Uri.parse(_absoluteUrl);
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception(
          l10n.text(
            '下载失败：HTTP ${response.statusCode}',
            'Download failed: HTTP ${response.statusCode}',
          ),
        );
      }
      final path = await saveDocFile(
        fileName: widget.file.name,
        bytes: response.bodyBytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.text('文件已保存：$path', 'File saved: $path')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.text('下载失败：$e', 'Download failed: $e')),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.file.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(_typeLabel, style: TextStyle(color: _color, fontSize: 12)),
                const SizedBox(height: 6),
                SelectableText(
                  _absoluteUrl,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                onPressed: _copyLink,
                icon: const Icon(Icons.link_outlined),
                tooltip: context.l10n.text('复制下载链接', 'Copy download link'),
              ),
              const SizedBox(height: 6),
              _downloading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton.filled(
                      onPressed: _download,
                      icon: const Icon(Icons.download_outlined),
                      tooltip: context.l10n.text('下载文件', 'Download file'),
                      style: IconButton.styleFrom(backgroundColor: _color),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class ResultItem extends StatelessWidget {
  const ResultItem({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => copyText(context, text),
              icon: const Icon(Icons.copy, size: 16),
              label: Text(context.l10n.copy),
            ),
          ),
        ],
      ),
    );
  }
}

class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.result});

  final ModuleRunResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.isAi
        ? const Color(0xFF059669)
        : const Color(0xFFEA580C);
    final label = result.isAi
        ? '${result.provider} · ${result.model}'
        : context.l10n.text('本地兜底', 'Local fallback');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<void> copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.text('已复制到剪贴板', 'Copied to clipboard')),
    ),
  );
}

void showShareCard(BuildContext context, ModuleRunResult result) {
  final cardText = result.items.take(2).join('\n\n');
  final controller = ScreenshotController();
  final screenWidth = MediaQuery.sizeOf(context).width;
  final cardWidth = math.min(340.0, screenWidth - 64);
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(context.l10n.text('分享卡片', 'Share Card')),
        content: Screenshot(
          controller: controller,
          child: ShareCardPreview(
            cardText: cardText,
            result: result,
            width: cardWidth,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.text('关闭', 'Close')),
          ),
          FilledButton.icon(
            onPressed: () {
              copyText(context, '${context.l10n.appName}\n\n$cardText');
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.copy),
            label: Text(context.l10n.text('复制卡片文案', 'Copy Card Text')),
          ),
          FilledButton.icon(
            onPressed: () => saveShareCard(context, controller),
            icon: const Icon(Icons.download_outlined),
            label: Text(context.l10n.text('保存图片', 'Save Image')),
          ),
        ],
      );
    },
  );
}

class ShareCardPreview extends StatelessWidget {
  const ShareCardPreview({
    super.key,
    required this.cardText,
    required this.result,
    required this.width,
  });

  final String cardText;
  final ModuleRunResult result;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.appTagline,
            style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Text(
            cardText,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0xFF334155)),
          const SizedBox(height: 10),
          Text(
            '${result.provider} · ${result.model}',
            style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Future<void> saveResultText(
  BuildContext context,
  ModuleRunResult result,
) async {
  try {
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final content = result.items.join('\n\n');
    final path = await saveTextFile(
      fileName: 'lingxi_ai_result_$timestamp.txt',
      content: content,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.text('结果已保存：$path', 'Result saved: $path')),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.text('保存失败：$error', 'Save failed: $error')),
      ),
    );
  }
}

Future<void> saveShareCard(
  BuildContext context,
  ScreenshotController controller,
) async {
  final l10n = context.l10n;
  try {
    final bytes = await controller.capture(pixelRatio: 3);
    if (bytes == null) {
      throw Exception(l10n.text('截图失败', 'Screenshot failed'));
    }
    await Gal.putImageBytes(bytes, name: 'lingxi_ai_share_card');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.text('PNG 图片已保存到相册', 'PNG image saved to Photos')),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.text('保存失败：$error', 'Save failed: $error')),
      ),
    );
  }
}

Future<void> saveImageBytes(
  BuildContext context,
  Uint8List bytes,
  String name,
) async {
  try {
    await Gal.putImageBytes(bytes, name: name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.text('图片已保存到相册', 'Image saved to Photos')),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.text('保存失败：$error', 'Save failed: $error')),
      ),
    );
  }
}

Future<void> saveImageUrl(BuildContext context, String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
    await Gal.putImageBytes(
      response.bodyBytes,
      name: 'lingxi_ai_generated_image',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.text('图片已保存到相册', 'Image saved to Photos')),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.text('保存失败：$error', 'Save failed: $error')),
      ),
    );
  }
}

String imageFileName(String label) {
  if (label.contains('穿搭')) return 'lingxi_ai_dressup_preview';
  return 'lingxi_ai_image_fix';
}
