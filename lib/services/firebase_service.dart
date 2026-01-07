import 'dart:async';
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

  // Realtime streams for admin dashboard (returns updated lists automatically)
  static Stream<List<StudentLog>> getStudentLogsStreamByDate(String date) {
    return FirebaseFirestore.instance
        .collection('student_logs')
        .where('date', isEqualTo: date)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentLog.fromFirestore(doc))
              .toList(),
        );
  }

  static Stream<List<TeacherLog>> getTeacherLogsStreamByDate(String date) {
    return FirebaseFirestore.instance
        .collection('teacher_logs')
        .where('date', isEqualTo: date)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TeacherLog.fromFirestore(doc))
              .toList(),
        );
  }

  static Stream<List<Student>> getAllStudentsStream() {
    return FirebaseFirestore.instance
        .collection('students')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
        );
  }

  static Stream<List<Teacher>> getAllTeachersStream() {
    return FirebaseFirestore.instance
        .collection('teachers')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList(),
        );
  }

  /// Aggregated dashboard metrics for students.
  /// Emits updated metrics whenever `student_logs` for the given date change.
  static Stream<DashboardMetrics> getDashboardMetricsStream({String? date}) {
    final dateStr = date ?? DateTime.now().toIso8601String().split('T')[0];
    return FirebaseFirestore.instance
        .collection('student_logs')
        .where('date', isEqualTo: dateStr)
        .snapshots()
        .map((snapshot) {
          final logs = snapshot.docs
              .map((d) => StudentLog.fromFirestore(d))
              .toList();

          int insideCampus = 0;
          int enteredToday = 0;
          int leftToday = 0;
          int lateStudents = 0;

          for (var log in logs) {
            if (log.isInsideCampus) insideCampus++;
            if (log.morningIn != null) enteredToday++;
            if (log.afternoonIn != null) enteredToday++;
            if (log.morningOut != null) leftToday++;
            if (log.afternoonOut != null) leftToday++;
            if (log.wasLate) lateStudents++;
          }

          return DashboardMetrics(
            studentsInsideCampus: insideCampus,
            studentsEnteredToday: enteredToday,
            studentsLeftToday: leftToday,
            lateStudentsToday: lateStudents,
          );
        });
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
  // Add these methods to FirebaseService class in firebase_service.dart

// Get students who are absent on a specific date
static Future<List<Student>> getAbsentStudents(String date) async {
  try {
    // Get all students
    final allStudents = await getAllStudents();
    
    // Get students who have logs for this date
    final attendanceLogs = await getStudentLogsByDate(date);
    final presentStudentLrns = attendanceLogs
        .where((log) => log.morningIn != null || log.afternoonIn != null)
        .map((log) => log.lrn ?? '')
        .toSet();
    
    // Filter out students who are present
    return allStudents.where((student) => 
      !presentStudentLrns.contains(student.lrn)
    ).toList();
  } catch (e) {
    print('Error getting absent students: $e');
    return [];
  }
}

// Get teachers who are absent on a specific date
static Future<List<Teacher>> getAbsentTeachers(String date) async {
  try {
    // Get all teachers
    final allTeachers = await getAllTeachers();
    
    // Get teachers who have logs for this date
    final attendanceLogs = await getTeacherLogsByDate(date);
    final presentTeacherLrns = attendanceLogs
        .where((log) => log.morningIn != null || log.afternoonIn != null)
        .map((log) => log.lrn ?? '')
        .toSet();
    
    // Filter out teachers who are present
    return allTeachers.where((teacher) => 
      !presentTeacherLrns.contains(teacher.lrn)
    ).toList();
  } catch (e) {
    print('Error getting absent teachers: $e');
    return [];
  }
}

// Get incomplete logs (missed time in/out)
static Future<List<Map<String, dynamic>>> getIncompleteLogs(String date) async {
  try {
    final incompleteLogs = <Map<String, dynamic>>[];
    
    // Check student logs
    final studentLogs = await getStudentLogsByDate(date);
    for (var log in studentLogs) {
      final issues = <String>[];
      
      if (log.morningIn != null && log.morningOut == null) {
        issues.add('Missed AM Out');
      }
      if (log.afternoonIn != null && log.afternoonOut == null) {
        issues.add('Missed PM Out');
      }
      if (log.morningOut != null && log.afternoonIn == null) {
        issues.add('Missed PM In');
      }
      
      if (issues.isNotEmpty) {
        incompleteLogs.add({
          'type': 'Student',
          'id': log.lrn ?? 'N/A',
          'name': log.fullName,
          'issues': issues,
        });
      }
    }
    
    // Check teacher logs
    final teacherLogs = await getTeacherLogsByDate(date);
    for (var log in teacherLogs) {
      final issues = <String>[];
      
      if (log.morningIn != null && log.morningOut == null) {
        issues.add('Missed AM Out');
      }
      if (log.afternoonIn != null && log.afternoonOut == null) {
        issues.add('Missed PM Out');
      }
      if (log.morningOut != null && log.afternoonIn == null) {
        issues.add('Missed PM In');
      }
      
      if (issues.isNotEmpty) {
        incompleteLogs.add({
          'type': 'Teacher',
          'id': log.lrn ?? 'N/A',
          'name': log.fullName,
          'issues': issues,
        });
      }
    }
    
    return incompleteLogs;
  } catch (e) {
    print('Error getting incomplete logs: $e');
    return [];
  }
}

// Stream versions for real-time updates
static Stream<List<Student>> getAbsentStudentsStream(String date) {
  return Stream.periodic(const Duration(seconds: 5))
      .asyncMap((_) => getAbsentStudents(date));
}

static Stream<List<Teacher>> getAbsentTeachersStream(String date) {
  return Stream.periodic(const Duration(seconds: 5))
      .asyncMap((_) => getAbsentTeachers(date));
}

static Stream<List<Map<String, dynamic>>> getIncompleteLogsStream(String date) {
  return Stream.periodic(const Duration(seconds: 5))
      .asyncMap((_) => getIncompleteLogs(date));
}

  /// Stream that computes early-riser leaderboard for students and teachers
  /// Defaults to the last `days` days (inclusive). An "early" arrival is
  /// considered arriving at or before 6:30 AM.
  static Stream<EarlyRiserResults> getEarlyRisersStream({int days = 30}) {
    final controller = StreamController<EarlyRiserResults>.broadcast();

    final startDate = DateTime.now().subtract(Duration(days: days - 1));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    final studentsQuery = FirebaseFirestore.instance
        .collection('student_logs')
        .where('date', isGreaterThanOrEqualTo: startDateStr);

    final teachersQuery = FirebaseFirestore.instance
        .collection('teacher_logs')
        .where('date', isGreaterThanOrEqualTo: startDateStr);

    List<QueryDocumentSnapshot>? latestStudentDocs;
    List<QueryDocumentSnapshot>? latestTeacherDocs;

    void computeAndEmit() {
      // Helper to compute early counts map from a list of docs and model parser
      Map<String, Map<String, dynamic>> studentCounts = {};

      if (latestStudentDocs != null) {
        for (var d in latestStudentDocs!) {
          final log = StudentLog.fromFirestore(d as DocumentSnapshot);
          final id = log.lrn ?? d.id;
          if (log.morningIn != null) {
            final dt = log.morningIn!;
            final cutoff = DateTime(dt.year, dt.month, dt.day, 6, 30);
            if (!dt.isAfter(cutoff)) {
              studentCounts.putIfAbsent(
                id,
                () => {'name': log.fullName, 'count': 0, 'lastTime': dt},
              );
              studentCounts[id]!['count'] = studentCounts[id]!['count'] + 1;
              // Update last time if this one is more recent
              if (dt.isAfter(studentCounts[id]!['lastTime'] as DateTime)) {
                studentCounts[id]!['lastTime'] = dt;
              }
            }
          }
        }
      }

      Map<String, Map<String, dynamic>> teacherCounts = {};
      if (latestTeacherDocs != null) {
        for (var d in latestTeacherDocs!) {
          final log = TeacherLog.fromFirestore(d as DocumentSnapshot);
          final id = log.lrn ?? d.id;
          if (log.morningIn != null) {
            final dt = log.morningIn!;
            final cutoff = DateTime(dt.year, dt.month, dt.day, 6, 30);
            if (!dt.isAfter(cutoff)) {
              teacherCounts.putIfAbsent(
                id,
                () => {'name': log.fullName, 'count': 0, 'lastTime': dt},
              );
              teacherCounts[id]!['count'] = teacherCounts[id]!['count'] + 1;
              // Update last time if this one is more recent
              if (dt.isAfter(teacherCounts[id]!['lastTime'] as DateTime)) {
                teacherCounts[id]!['lastTime'] = dt;
              }
            }
          }
        }
      }
      

      // Convert to lists and sort by most recent early arrival time
      List<EarlyRiser> studentsList = studentCounts.entries
          .map(
            (e) => EarlyRiser(
              id: e.key,
              name: e.value['name'] ?? 'N/A',
              earlyCount: e.value['count'] ?? 0,
              points: 0,
              lastEarlyTime: e.value['lastTime'],
            ),
          )
          .toList();

      List<EarlyRiser> teachersList = teacherCounts.entries
          .map(
            (e) => EarlyRiser(
              id: e.key,
              name: e.value['name'] ?? 'N/A',
              earlyCount: e.value['count'] ?? 0,
              points: 0,
              lastEarlyTime: e.value['lastTime'],
            ),
          )
          .toList();

      // Sort by most recent early arrival time (descending - most recent first)
      studentsList.sort((a, b) {
        if (a.lastEarlyTime == null && b.lastEarlyTime == null) return 0;
        if (a.lastEarlyTime == null) return 1;
        if (b.lastEarlyTime == null) return -1;
        return b.lastEarlyTime!.compareTo(a.lastEarlyTime!);
      });
      
      teachersList.sort((a, b) {
        if (a.lastEarlyTime == null && b.lastEarlyTime == null) return 0;
        if (a.lastEarlyTime == null) return 1;
        if (b.lastEarlyTime == null) return -1;
        return b.lastEarlyTime!.compareTo(a.lastEarlyTime!);
      });

      // Assign points by ranking
      int assignPoints(int index) {
        final pos = index + 1;
        if (pos == 1) return 5;
        if (pos == 2) return 4;
        if (pos == 3) return 3;
        if (pos >= 4 && pos <= 10) return 2;
        return 1;
      }

      studentsList = studentsList
          .asMap()
          .entries
          .map(
            (e) => EarlyRiser(
              id: e.value.id,
              name: e.value.name,
              earlyCount: e.value.earlyCount,
              points: assignPoints(e.key),
            ),
          )
          .toList();

      teachersList = teachersList
          .asMap()
          .entries
          .map(
            (e) => EarlyRiser(
              id: e.value.id,
              name: e.value.name,
              earlyCount: e.value.earlyCount,
              points: assignPoints(e.key),
            ),
          )
          .toList();

      controller.add(
        EarlyRiserResults(students: studentsList, teachers: teachersList),
      );
    }

    final studentsSub = studentsQuery.snapshots().listen((snap) {
      latestStudentDocs = snap.docs;
      computeAndEmit();
    });

    final teachersSub = teachersQuery.snapshots().listen((snap) {
      latestTeacherDocs = snap.docs;
      computeAndEmit();
    });

    controller.onCancel = () async {
      await studentsSub.cancel();
      await teachersSub.cancel();
      await controller.close();
    };

    return controller.stream;
  }
}


/// Simple data holder for dashboard metrics
class DashboardMetrics {
  final int studentsInsideCampus;
  final int studentsEnteredToday;
  final int studentsLeftToday;
  final int lateStudentsToday;

  DashboardMetrics({
    required this.studentsInsideCampus,
    required this.studentsEnteredToday,
    required this.studentsLeftToday,
    required this.lateStudentsToday,
  });
}

/// Early riser data holder
class EarlyRiser {
  final String id;
  final String name;
  final int earlyCount;
  final int points;
  final DateTime? lastEarlyTime; // Most recent early arrival time

  EarlyRiser({
    required this.id,
    required this.name,
    required this.earlyCount,
    required this.points,
    this.lastEarlyTime,
  });
}

/// Aggregated early riser results for students and teachers
class EarlyRiserResults {
  final List<EarlyRiser> students;
  final List<EarlyRiser> teachers;

  EarlyRiserResults({required this.students, required this.teachers});
}
