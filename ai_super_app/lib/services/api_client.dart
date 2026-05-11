import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_models.dart';

const _defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.kktu.top',
);

const _apiUrlKey = 'saved_api_base_url';

/// Global mutable API base URL, initialized from saved preferences.
String apiBaseUrl = _defaultApiBaseUrl;

/// Old local default that should be migrated to the new cloud URL.
const _oldLocalDefault = 'http://192.168.1.4:8000';

/// Load saved API URL from SharedPreferences. Call once at app startup.
Future<void> loadSavedApiUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_apiUrlKey);
  if (saved != null && saved.isNotEmpty) {
    // Migrate old local address to new cloud address
    if (saved == _oldLocalDefault) {
      apiBaseUrl = _defaultApiBaseUrl;
      await prefs.setString(_apiUrlKey, _defaultApiBaseUrl);
    } else {
      apiBaseUrl = saved;
    }
  }
}

/// Save a new API URL to SharedPreferences and update the global variable.
Future<void> saveApiUrl(String url) async {
  apiBaseUrl = url;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_apiUrlKey, url);
}

class ApiClient {
  const ApiClient({this.baseUrl});

  final String? baseUrl;

  String get _base => baseUrl ?? apiBaseUrl;

  Future<IntentRoute> routeIntent(String text) async {
    final response = await http.post(
      Uri.parse('$_base/api/intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    return IntentRoute.fromJson(_decode(response));
  }

  Future<ModuleRunResult> runModule({
    required String moduleId,
    required String text,
    String mode = 'prototype',
    Map<String, dynamic> payload = const {},
  }) async {
    final response = await http.post(
      Uri.parse('$_base/api/modules/$moduleId/run'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'mode': mode, 'payload': payload}),
    );
    return ModuleRunResult.fromJson(_decode(response));
  }

  Future<ModuleRunResult> runCompanionVoice({
    required String audioBase64,
    required String format,
    Map<String, dynamic> payload = const {},
  }) async {
    final response = await http.post(
      Uri.parse('$_base/api/modules/companion/voice'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'audio_base64': audioBase64, 'format': format, 'payload': payload}),
    );
    return ModuleRunResult.fromJson(_decode(response));
  }

  Future<Map<String, dynamic>> provider() async {
    final response = await http.get(Uri.parse('$_base/api/ai/provider'));
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('HTTP ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
