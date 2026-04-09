import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExportHelper {
  static Future<void> saveAndShare({
    required String content,
    required String fileName,
  }) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '$fileName.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
