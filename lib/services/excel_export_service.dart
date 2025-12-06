import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

// For web download
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExcelExportService {
  /// Export student logs to Excel
  static Future<void> exportStudentLogs(
    List<StudentLog> logs,
    DateTime date,
  ) async {
    final excel = Excel.createExcel();
    final sheetName = 'Student Attendance';

    // Remove default sheet and create new one
    excel.delete('Sheet1');
    final sheet = excel[sheetName];

    // Style for header
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#1E3A8A',
      fontColorHex: '#FFFFFF',
      horizontalAlign: HorizontalAlign.Center,
    );

    // Add headers
    final headers = [
      'No.',
      'LRN',
      'Full Name',
      'Section',
      'AM In',
      'AM Out',
      'PM In',
      'PM Out',
      'Status',
      'Address',
      'Emergency Contact',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i];
      cell.cellStyle = headerStyle;
    }

    // Add data rows
    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      final rowIndex = i + 1;

      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
              )
              .value =
          i + 1;
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
              )
              .value =
          log.lrn ?? 'N/A';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = log
          .fullName;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = log
          .yearAndSection;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = _formatTime(
        log.morningIn,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = _formatTime(
        log.morningOut,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = _formatTime(
        log.afternoonIn,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = _formatTime(
        log.afternoonOut,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = log
          .attendanceStatus;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = log
          .address;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = log
          .emergencyContact;
    }

    // Generate filename
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final filename = 'Student_Attendance_$dateStr.xlsx';

    // Save and download
    await _downloadExcel(excel, filename);
  }

  /// Export teacher logs to Excel
  static Future<void> exportTeacherLogs(
    List<TeacherLog> logs,
    DateTime date,
  ) async {
    final excel = Excel.createExcel();
    final sheetName = 'Teacher Attendance';

    // Remove default sheet and create new one
    excel.delete('Sheet1');
    final sheet = excel[sheetName];

    // Style for header
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#1E3A8A',
      fontColorHex: '#FFFFFF',
      horizontalAlign: HorizontalAlign.Center,
    );

    // Add headers
    final headers = [
      'No.',
      'Employee ID',
      'Full Name',
      'AM In',
      'AM Out',
      'PM In',
      'PM Out',
      'Status',
      'Address',
      'Emergency Contact',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = headers[i];
      cell.cellStyle = headerStyle;
    }

    // Add data rows
    for (int i = 0; i < logs.length; i++) {
      final log = logs[i];
      final rowIndex = i + 1;

      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
              )
              .value =
          i + 1;
      sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
              )
              .value =
          log.lrn ?? 'N/A';
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = log
          .fullName;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = _formatTime(
        log.morningIn,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = _formatTime(
        log.morningOut,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = _formatTime(
        log.afternoonIn,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = _formatTime(
        log.afternoonOut,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = log
          .attendanceStatus;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = log
          .address;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = log
          .emergencyContact;
    }

    // Generate filename
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final filename = 'Teacher_Attendance_$dateStr.xlsx';

    // Save and download
    await _downloadExcel(excel, filename);
  }

  /// Format time for Excel
  static String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('hh:mm a').format(time);
  }

  /// Download Excel file (web)
  static Future<void> _downloadExcel(Excel excel, String filename) async {
    final bytes = excel.save();
    if (bytes != null) {
      final blob = html.Blob([
        Uint8List.fromList(bytes),
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.Url.revokeObjectUrl(url);
    }
  }
}
