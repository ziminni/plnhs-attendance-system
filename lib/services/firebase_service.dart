import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔐 Get currently logged-in user
  User? get currentUser => _auth.currentUser;

  Future<String> getRole() async {
    final uid = currentUser?.uid;

    if (uid == null) {
      return "User Null";
    }

    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'Unknown';
  }

  // Add or update student data using LRN as document ID
  static Future<void> addStudentData(Map<String, dynamic> data) async {
    String cleanedLrn = data['lrn']?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
    await FirebaseFirestore.instance
        .collection('students')
        .doc(cleanedLrn)
        .set(data);
  }

  // Add or update teacher data using LRN as document ID
  static Future<void> addTeacherData(Map<String, dynamic> data) async {
    String cleanedLrn = data['lrn']?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
    await FirebaseFirestore.instance
        .collection('teachers')
        .doc(cleanedLrn)
        .set(data);
  }

  // Get student data by LRN
  static Future<Map<String, dynamic>?> getStudentByLrn(String lrn) async {
    try {
      String cleanedLrn = lrn.trim().replaceAll(RegExp(r'\s+'), '');
      print('Firebase Instance: ${FirebaseFirestore.instance.app.name}');
      print('Searching for cleaned LRN: $cleanedLrn');

      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(cleanedLrn)
          .get();
      print('Queried document ID: $cleanedLrn, Exists: ${studentDoc.exists}');
      if (studentDoc.exists) {
        return studentDoc.data() as Map<String, dynamic>?;
      }

      var fallbackQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('lrn', isEqualTo: cleanedLrn)
          .limit(1)
          .get();
      print('Fallback query for lrn=$cleanedLrn, Docs found: ${fallbackQuery.docs.length}');
      if (fallbackQuery.docs.isNotEmpty) {
        var docData = fallbackQuery.docs.first.data() as Map<String, dynamic>;
        if (docData.containsKey('lrn')) {
          docData['lrn'] = docData['lrn'].toString().trim().replaceAll(RegExp(r'\s+'), '');
        }
        return docData;
      }
      return null;
    } catch (e) {
      print('Error getting student by LRN: $e');
      return null;
    }
  }

  // Log attendance for a student with date, preserving existing data
  static Future<void> logAttendance(String lrn, String attendanceType) async {
    try {
      String cleanedLrn = lrn.trim().replaceAll(RegExp(r'\s+'), '');
      DocumentSnapshot studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(cleanedLrn)
          .get();
      if (!studentDoc.exists) {
        throw Exception('Student not found for LRN: $cleanedLrn');
      }
      var studentData = studentDoc.data() as Map<String, dynamic>;
      String fullName = '${studentData['firstname'] ?? ''} ${studentData['middlename'] ?? ''} ${studentData['lastname'] ?? ''}'.trim();
      String yearAndSection = studentData['grade_and_section'] ?? 'Unknown';
      String address = studentData['address'] ?? 'Unknown';
      String emergencyContact = studentData['guardian_contact'] ?? 'Unknown';

      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      DocumentSnapshot logDoc = await FirebaseFirestore.instance
          .collection('student_logs')
          .doc(cleanedLrn)
          .get();
      Map<String, dynamic> existingData = logDoc.exists ? (logDoc.data() as Map<String, dynamic>) : {};
      if (!existingData.containsKey('date') || existingData['date'] != currentDate) {
        existingData = {
          'fullName': fullName,
          'yearAndSection': yearAndSection,
          'address': address,
          'emergencyContact': emergencyContact,
          'date': currentDate,
          'morningIn': null,
          'morningOut': null,
          'afternoonIn': null,
          'afternoonOut': null,
        };
      }

      switch (attendanceType.toLowerCase()) {
        case 'morning_in':
          existingData['morningIn'] = FieldValue.serverTimestamp();
          break;
        case 'morning_out':
          existingData['morningOut'] = FieldValue.serverTimestamp();
          break;
        case 'afternoon_in':
          existingData['afternoonIn'] = FieldValue.serverTimestamp();
          break;
        case 'afternoon_out':
          existingData['afternoonOut'] = FieldValue.serverTimestamp();
          break;
        default:
          throw Exception('Invalid attendance type: $attendanceType');
      }

      await FirebaseFirestore.instance
          .collection('student_logs')
          .doc(cleanedLrn)
          .set(existingData, SetOptions(merge: true));
      print('Successfully logged attendance for student LRN: $cleanedLrn, Type: $attendanceType');
    } catch (e) {
      print('Error logging student attendance: $e');
      throw e;
    }
  }

  // Log attendance for a teacher with date, preserving existing data
  static Future<void> logTeacherAttendance(String lrn, String attendanceType) async {
    try {
      String cleanedLrn = lrn.trim().replaceAll(RegExp(r'\s+'), '');
      DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(cleanedLrn)
          .get();
      if (!teacherDoc.exists) {
        throw Exception('Teacher not found for LRN: $cleanedLrn');
      }
      var teacherData = teacherDoc.data() as Map<String, dynamic>;
      String fullName = teacherData['fullname'] ?? 'Unknown';
      String address = teacherData['address'] ?? 'Unknown';
      String emergencyContact = teacherData['emergency_contact'] ?? 'Unknown';

      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      DocumentSnapshot logDoc = await FirebaseFirestore.instance
          .collection('teacher_logs')
          .doc(cleanedLrn)
          .get();
      Map<String, dynamic> existingData = logDoc.exists ? (logDoc.data() as Map<String, dynamic>) : {};
      if (!existingData.containsKey('date') || existingData['date'] != currentDate) {
        existingData = {
          'fullName': fullName,
          'address': address,
          'emergencyContact': emergencyContact,
          'date': currentDate,
          'morningIn': null,
          'morningOut': null,
          'afternoonIn': null,
          'afternoonOut': null,
        };
      }

      switch (attendanceType.toLowerCase()) {
        case 'morning_in':
          existingData['morningIn'] = FieldValue.serverTimestamp();
          break;
        case 'morning_out':
          existingData['morningOut'] = FieldValue.serverTimestamp();
          break;
        case 'afternoon_in':
          existingData['afternoonIn'] = FieldValue.serverTimestamp();
          break;
        case 'afternoon_out':
          existingData['afternoonOut'] = FieldValue.serverTimestamp();
          break;
        default:
          throw Exception('Invalid attendance type: $attendanceType');
      }

      await FirebaseFirestore.instance
          .collection('teacher_logs')
          .doc(cleanedLrn)
          .set(existingData, SetOptions(merge: true));
      print('Successfully logged attendance for teacher LRN: $cleanedLrn, Type: $attendanceType');
    } catch (e) {
      print('Error logging teacher attendance: $e');
      throw e;
    }
  }

  // Get student logs filtered by date
  static Future<List<Map<String, dynamic>>> getStudentLogsByDate(String date) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('student_logs')
          .where('date', isEqualTo: date)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting student logs by date: $e');
      return [];
    }
  }

  // Get teacher logs filtered by date
  static Future<List<Map<String, dynamic>>> getTeacherLogsByDate(String date) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('teacher_logs')
          .where('date', isEqualTo: date)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting teacher logs by date: $e');
      return [];
    }
  }
}