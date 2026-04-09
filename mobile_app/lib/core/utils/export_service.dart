import 'package:flutter/material.dart';
import 'export_helper.dart';

class ExportService {
  /// Exports data to a CSV file and handles saving/sharing based on platform.
  /// [data] is a list of maps where each map represents a row.
  /// [fileName] is the name of the file (e.g., 'users_report').
  static Future<void> exportToCsv({
    required BuildContext context,
    required List<Map<String, dynamic>> data,
    required String fileName,
  }) async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu để xuất')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate CSV content
      final headers = data.first.keys.toList();
      final buffer = StringBuffer();
      
      // Add UTF-8 BOM for Excel compatibility
      buffer.write('\uFEFF'); 
      
      // Headers
      buffer.writeln(headers.join(','));

      // Rows
      for (var row in data) {
        final values = headers.map((header) {
          var val = row[header] ?? '';
          String valStr = val.toString().replaceAll('"', '""');
          if (valStr.contains(',') || valStr.contains('\n') || valStr.contains('"')) {
            valStr = '"$valStr"';
          }
          return valStr;
        });
        buffer.writeln(values.join(','));
      }

      // Close loading indicator
      if (context.mounted) Navigator.pop(context);

      // Use platform-agnostic helper to save and share
      await ExportHelper.saveAndShare(
        content: buffer.toString(),
        fileName: fileName,
      );

    } catch (e) {
      if (context.mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất dữ liệu: $e')),
        );
      }
    }
  }
}
