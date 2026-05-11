import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String> saveTextFile({required String fileName, required String content}) async {
  final directory = await getApplicationDocumentsDirectory();
  final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
  final file = File('${directory.path}/$safeName');
  await file.writeAsString(content);
  return file.path;
}

Future<String> saveDocFile({required String fileName, required Uint8List bytes}) async {
  final directory = await getApplicationDocumentsDirectory();
  final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
  final file = File('${directory.path}/$safeName');
  await file.writeAsBytes(bytes);
  return file.path;
}