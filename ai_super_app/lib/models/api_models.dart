class IntentRoute {
  const IntentRoute({required this.moduleId, required this.confidence});

  factory IntentRoute.fromJson(Map<String, dynamic> json) {
    return IntentRoute(
      moduleId: json['module_id'] as String? ?? 'writing',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    );
  }

  final String moduleId;
  final double confidence;
}

class DocFile {
  const DocFile({required this.name, required this.type, required this.url});

  factory DocFile.fromJson(Map<String, dynamic> json) {
    return DocFile(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  final String name;
  final String type;
  final String url;
}

class ModuleRunResult {
  const ModuleRunResult({
    required this.source,
    required this.provider,
    required this.model,
    required this.items,
    required this.imageUrls,
    required this.files,
    required this.tips,
    required this.error,
    this.audioBase64 = '',
    this.audioFormat = 'wav',
  });

  factory ModuleRunResult.fromJson(Map<String, dynamic> json) {
    return ModuleRunResult(
      source: json['source'] as String? ?? 'fallback',
      provider: json['provider'] as String? ?? 'local',
      model: json['model'] as String? ?? 'mock',
      items: (json['result'] as List<dynamic>? ?? []).map((item) => item.toString()).toList(),
      imageUrls: (json['images'] as List<dynamic>? ?? []).map((item) => item.toString()).toList(),
      files: (json['files'] as List<dynamic>? ?? []).map((item) => DocFile.fromJson(item as Map<String, dynamic>)).toList(),
      tips: (json['tips'] as List<dynamic>? ?? []).map((item) => item.toString()).toList(),
      error: json['error'] as String?,
      audioBase64: json['audio_base64'] as String? ?? '',
      audioFormat: json['audio_format'] as String? ?? 'wav',
    );
  }

  final String source;
  final String provider;
  final String model;
  final List<String> items;
  final List<String> imageUrls;
  final List<DocFile> files;
  final List<String> tips;
  final String? error;
  final String audioBase64;
  final String audioFormat;

  bool get isAi => source == 'ai';
  bool get hasAudio => audioBase64.isNotEmpty;
}
