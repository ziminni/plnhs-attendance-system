import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'firebase_service.dart';
import '../models/models.dart';

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
          // Create Student model from Excel data
          final student = Student(
            lrn: row[3]?.value.toString() ?? '',
            lastname: row[0]?.value.toString() ?? '',
            firstname: row[1]?.value.toString() ?? '',
            middlename: row[2]?.value.toString(),
            gradeAndSection: row[5]?.value.toString(),
            address: row[9]?.value.toString(),
            guardianContact: row[10]?.value.toString(),
          );

          // Add additional fields not in model
          Map<String, dynamic> studentData = student.toMap();
          studentData['label'] = 'student';
          studentData['birthdate'] = row[4]?.value.toString();
          studentData['adviser'] = row[6]?.value.toString();
          studentData['guardian_name'] = row[7]?.value.toString();
          studentData['relationship'] = row[8]?.value.toString();

          print("Uploading this student data: $studentData");
          await FirebaseService.addStudentDataFromMap(studentData);
        } else if (label.toLowerCase() == 'teacher') {
          // Excel format: lrn | lastname | firstname | middlename | department | position | address | emergency_contact
          String lastname = row[1]?.value.toString() ?? '';
          String firstname = row[2]?.value.toString() ?? '';
          String middlename = row[3]?.value.toString() ?? '';

          // Combine names into fullname
          String fullname = '$firstname $middlename $lastname'
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

          // Create Teacher model from Excel data
          final teacher = Teacher(
            lrn: row[0]?.value.toString() ?? '', // Employee ID
            fullname: fullname,
            department: row[4]?.value.toString(),
            position: row[5]?.value.toString(),
            address: row[6]?.value.toString(),
            emergencyContact: row[7]?.value.toString(),
          );

          // Add additional fields not in model
          Map<String, dynamic> teacherData = teacher.toMap();
          teacherData['label'] = 'teacher';
          teacherData['lastname'] = lastname;
          teacherData['firstname'] = firstname;
          teacherData['middlename'] = middlename;

          print("Uploading this teacher data: $teacherData");
          await FirebaseService.addTeacherDataFromMap(teacherData);
        }
      }
    }
    print("✅ Upload successful!");
  } else {
    print("❌ No file selected");
  }
}
