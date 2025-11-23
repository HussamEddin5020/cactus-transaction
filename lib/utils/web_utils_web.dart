// ignore: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:html' as html;

@pragma('dart2js:noInline')
void downloadCsvWeb(String csvContent, String fileName) {
  final blob = html.Blob([csvContent]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

