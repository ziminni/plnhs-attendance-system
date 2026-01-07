import 'package:excel/excel.dart';
import 'excel_export_service.dart';

extension ExcelExportServiceStub on ExcelExportService {
  static Future<void> _downloadExcel(Excel excel, String filename) async {
    // No-op for non-web platforms
    throw UnimplementedError('Excel download is only implemented for web.');
  }
}
