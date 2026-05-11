import 'package:flutter/services.dart';

Future<String> saveTextFile({required String fileName, required String content}) async {
  await Clipboard.setData(ClipboardData(text: content));
  return '当前平台暂不支持直接保存文件，内容已复制到剪贴板';
}

Future<String> saveDocFile({required String fileName, required Uint8List bytes}) async {
  return '当前平台暂不支持直接保存文件';
}