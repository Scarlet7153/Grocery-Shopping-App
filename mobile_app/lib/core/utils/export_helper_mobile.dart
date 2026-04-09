import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportHelper {
  static Future<void> saveAndShare({
    required String content,
    required String fileName,
  }) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$fileName.csv';
    final file = File(path);
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(path)],
      text: 'Báo cáo: $fileName',
      subject: 'Xuất dữ liệu $fileName',
    );
  }
}
