import 'package:flutter/foundation.dart';

// ignore: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:html' as html;

void downloadCsv(String csvContent, String fileName) {
  if (!kIsWeb) {
    debugPrint('CSV download is only available on web');
    return;
  }
  
  final blob = html.Blob([csvContent]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
