import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'dart:html' as html;

import 'excel_export_service.dart';

extension ExcelExportServiceWeb on ExcelExportService {
  static Future<void> _downloadExcel(Excel excel, String filename) async {
    final bytes = excel.save();
    if (bytes != null) {
      final blob = html.Blob([
        Uint8List.fromList(bytes),
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
