import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔐 Get currently logged-in user
  User? get currentUser => _auth.currentUser;

  Future<UserRole> getRole() async {
    final uid = currentUser?.uid;

    if (uid == null) {
      print("❌ No current user UID");
      return UserRole.unknown;
    }

    print("🔍 Fetching role for UID: $uid");
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      print("❌ Document does not exist for UID: $uid");
      return UserRole.unknown;
    }

    final roleStr = doc.data()?['role'];
    print("📄 Role string from Firestore: $roleStr");

    return UserRole.fromString(roleStr);
  }

  /// Get current user with role information
  Future<AppUser?> getCurrentAppUser() async {
    final firebaseUser = currentUser;
    if (firebaseUser == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    return AppUser.fromFirebaseUser(firebaseUser, doc.data());
  }

  // Add or update student data using LRN as document ID
  static Future<void> addStudentData(Student student) async {
    String cleanedLrn = student.lrn.trim().replaceAll(RegExp(r'\s+'), '');
    await FirebaseFirestore.instance
        .collection('students')
        .doc(cleanedLrn)
        .set(student.toMap());
  }

  // Add or update student data from Map (legacy support)
  static Future<void> addStudentDataFromMap(Map<String, dynamic> data) async {
    String cleanedLrn =
        data['lrn']?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
    await FirebaseFirestore.instance
        .collection('students')
        .doc(cleanedLrn)
        .set(data);
  }

  // Add or update teacher data using LRN as document ID
  static Future<void> addTeacherData(Teacher teacher) async {
    String cleanedLrn = teacher.lrn.trim().replaceAll(RegExp(r'\s+'), '');
    await FirebaseFirestore.instance
        .collection('teachers')
        .doc(cleanedLrn)
        .set(teacher.toMap());
  }

  // Add or update teacher data from Map (legacy support)
  static Future<void> addTeacherDataFromMap(Map<String, dynamic> data) async {
    String cleanedLrn =
        data['lrn']?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
    await FirebaseFirestore.instance
        .collection('teachers')
        .doc(cleanedLrn)
        .set(data);
  }

  // Get student by LRN - returns Student model
  static Future<Student?> getStudentByLrn(String lrn) async {
    try {
      final cleanedLrn = lrn.trim().replaceAll(RegExp(r'\s+'), '');

      // Try document ID first (fastest)
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(cleanedLrn)
          .get();

      if (studentDoc.exists) {
        return Student.fromFirestore(studentDoc);
      }

      // Fallback: query by lrn field
      final fallbackQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('lrn', isEqualTo: cleanedLrn)
          .limit(1)
          .get();

      if (fallbackQuery.docs.isNotEmpty) {
        return Student.fromFirestore(fallbackQuery.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting student by LRN: $e');
      return null;
    }
  }

  // Get teacher by LRN - returns Teacher model
  static Future<Teacher?> getTeacherByLrn(String lrn) async {
    try {
      final cleanedLrn = lrn.trim().replaceAll(RegExp(r'\s+'), '');

      // Try document ID first (fastest)
      final teacherDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(cleanedLrn)
          .get();

      if (teacherDoc.exists) {
        return Teacher.fromFirestore(teacherDoc);
      }

      // Fallback: query by lrn field
      final fallbackQuery = await FirebaseFirestore.instance
          .collection('teachers')
          .where('lrn', isEqualTo: cleanedLrn)
          .limit(1)
          .get();

      if (fallbackQuery.docs.isNotEmpty) {
        return Teacher.fromFirestore(fallbackQuery.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting teacher by LRN: $e');
      return null;
    }
  }

  // Log attendance for a student with date, preserving existing data
  static Future<void> logAttendance(
    String lrn,
    AttendanceType attendanceType,
  ) async {
    try {
      String cleanedLrn = lrn.trim().replaceAll(RegExp(r'\s+'), '');

      final student = await getStudentByLrn(cleanedLrn);
      if (student == null) {
        throw Exception('Student not found for LRN: $cleanedLrn');
      }

      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      DocumentSnapshot logDoc = await FirebaseFirestore.instance
          .collection('student_logs')
          .doc(cleanedLrn)
          .get();

      Map<String, dynamic> existingData = logDoc.exists
          ? (logDoc.data() as Map<String, dynamic>)
          : {};

      if (!existingData.containsKey('date') ||
          existingData['date'] != currentDate) {
        existingData = {
          'fullName': student.fullName,
          'yearAndSection': student.gradeAndSection ?? 'Unknown',
          'address': student.address ?? 'Unknown',
          'emergencyContact': student.guardianContact ?? 'Unknown',
          'date': currentDate,
          'morningIn': null,
          'morningOut': null,
          'afternoonIn': null,
          'afternoonOut': null,
        };
      }

      existingData[attendanceType.firestoreField] =
          FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('student_logs')
          .doc(cleanedLrn)
          .set(existingData, SetOptions(merge: true));
      print(
        'Successfully logged attendance for student LRN: $cleanedLrn, Type: ${attendanceType.displayName}',
      );
    } catch (e) {
      print('Error logging student attendance: $e');
      rethrow;
    }
  }

  // Legacy method for logging attendance with string type
  static Future<void> logAttendanceString(
    String lrn,
    String attendanceTypeStr,
  ) async {
    final attendanceType = AttendanceType.fromString(attendanceTypeStr);
    await logAttendance(lrn, attendanceType);
  }

  // Log attendance for a teacher with date, preserving existing data
  static Future<void> logTeacherAttendance(
    String lrn,
    AttendanceType attendanceType,
  ) async {
    try {
      String cleanedLrn = lrn.trim().replaceAll(RegExp(r'\s+'), '');

      final teacher = await getTeacherByLrn(cleanedLrn);
      if (teacher == null) {
        throw Exception('Teacher not found for LRN: $cleanedLrn');
      }

      String currentDate = DateTime.now().toIso8601String().split('T')[0];

      DocumentSnapshot logDoc = await FirebaseFirestore.instance
          .collection('teacher_logs')
          .doc(cleanedLrn)
          .get();

      Map<String, dynamic> existingData = logDoc.exists
          ? (logDoc.data() as Map<String, dynamic>)
          : {};

      if (!existingData.containsKey('date') ||
          existingData['date'] != currentDate) {
        existingData = {
          'fullName': teacher.fullname,
          'lrn': cleanedLrn,
          'address': teacher.address ?? 'Unknown',
          'emergencyContact': teacher.emergencyContact ?? 'Unknown',
          'date': currentDate,
          'morningIn': null,
          'morningOut': null,
          'afternoonIn': null,
          'afternoonOut': null,
        };
      } else {
        // Ensure fullName is always set even on existing records
        if (existingData['fullName'] == null ||
            existingData['fullName'] == 'N/A' ||
            existingData['fullName'] == '') {
          existingData['fullName'] = teacher.fullname;
        }
      }

      existingData[attendanceType.firestoreField] =
          FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('teacher_logs')
          .doc(cleanedLrn)
          .set(existingData, SetOptions(merge: true));
      print(
        'Successfully logged attendance for teacher LRN: $cleanedLrn, Type: ${attendanceType.displayName}',
      );
    } catch (e) {
      print('Error logging teacher attendance: $e');
      rethrow;
    }
  }

  // Legacy method for logging teacher attendance with string type
  static Future<void> logTeacherAttendanceString(
    String lrn,
    String attendanceTypeStr,
  ) async {
    final attendanceType = AttendanceType.fromString(attendanceTypeStr);
    await logTeacherAttendance(lrn, attendanceType);
  }

  // Get student logs filtered by date - returns List<StudentLog>
  static Future<List<StudentLog>> getStudentLogsByDate(String date) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('student_logs')
          .where('date', isEqualTo: date)
          .get();
      return snapshot.docs.map((doc) => StudentLog.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting student logs by date: $e');
      return [];
    }
  }

  // Get teacher logs filtered by date - returns List<TeacherLog>
  static Future<List<TeacherLog>> getTeacherLogsByDate(String date) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('teacher_logs')
          .where('date', isEqualTo: date)
          .get();
      return snapshot.docs.map((doc) => TeacherLog.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting teacher logs by date: $e');
      return [];
    }
  }

  // Get all students
  static Future<List<Student>> getAllStudents() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();
      return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all students: $e');
      return [];
    }
  }

  // Get all teachers
  static Future<List<Teacher>> getAllTeachers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .get();
      return snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting all teachers: $e');
      return [];
    }
  }

  // Delete student
  static Future<void> deleteStudent(String lrn) async {
    String cleanedLrn = lrn.trim().replaceAll(RegExp(r'\s+'), '');
    await FirebaseFirestore.instance
        .collection('students')
        .doc(cleanedLrn)
        .delete();
  }

  // Delete teacher
  static Future<void> deleteTeacher(String lrn) async {
    String cleanedLrn = lrn.trim().replaceAll(RegExp(r'\s+'), '');
    await FirebaseFirestore.instance
        .collection('teachers')
        .doc(cleanedLrn)
        .delete();
  }

  // Update student
  static Future<void> updateStudent(Student student) async {
    String cleanedLrn = student.lrn.trim().replaceAll(RegExp(r'\s+'), '');
    await FirebaseFirestore.instance
        .collection('students')
        .doc(cleanedLrn)
        .update(student.toMap());
  }

  // Update teacher
  static Future<void> updateTeacher(Teacher teacher) async {
    String cleanedLrn = teacher.lrn.trim().replaceAll(RegExp(r'\s+'), '');
    await FirebaseFirestore.instance
        .collection('teachers')
        .doc(cleanedLrn)
        .update(teacher.toMap());
  }
}
