import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'firebase_service.dart';

Future<void> importExcelAndUploadToFirebase(String label) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    withData: true, // This is required for web!
  );

  if (result != null) {
    Uint8List? fileBytes = result.files.single.bytes;

    var excel = Excel.decodeBytes(fileBytes!);

    for (var table in excel.tables.keys) {
      List<Data?> headers = excel.tables[table]!.rows[0];

      for (int i = 1; i < excel.tables[table]!.rows.length; i++) {
        var row = excel.tables[table]!.rows[i];

        if (label.toLowerCase() == 'student') {
          // Map Excel columns to student firestore fields
          Map<String, dynamic> studentData = {
            'label': 'student',
            'lastname': row[0]?.value.toString(),
            'firstname': row[1]?.value.toString(),
            'middlename': row[2]?.value.toString(),
            'lrn': row[3]?.value.toString(),
            'birthdate': row[4]?.value.toString(),
            'grade_and_section': row[5]?.value.toString(),
            'adviser': row[6]?.value.toString(),
            'guardian_name': row[7]?.value.toString(),
            'relationship': row[8]?.value.toString(),
            'address': row[9]?.value.toString(),
            'guardian_contact': row[10]?.value.toString(),
          };

          print("Uploading this student data: $studentData");
          await FirebaseService.addStudentData(studentData);
        } else if (label.toLowerCase() == 'teacher') {
          // Map Excel columns to teacher firestore fields
          Map<String, dynamic> teacherData = {
            'label': 'teacher',
            'lrn': row[0]?.value.toString(), // Employee number
            'lastname': row[1]?.value.toString(),
            'fullname': row[2]?.value.toString(),
            'middlename': row[3]?.value.toString(),
            'address': row[4]?.value.toString(),
            'emergency_contact': row[5]?.value.toString(),
          };

          print("Uploading this teacher data: $teacherData");
          await FirebaseService.addTeacherData(teacherData);
        }
      }
    }
    print("✅ Upload successful!");
  } else {
    print("❌ No file selected");
  }
}