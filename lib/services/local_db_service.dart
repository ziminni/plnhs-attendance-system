import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class LocalDbService {
  static Database? _db;
  static final LocalDbService _instance = LocalDbService._internal();

  LocalDbService._internal();

  factory LocalDbService() {
    return _instance;
  }

  static const String staffTable = 'staff';
  static const String attendanceTable = 'attendance';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'attendance.db');

    // Delete old database to force recreation with new schema
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $staffTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fullname TEXT,
            id_number TEXT UNIQUE,
            phone_number TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE $attendanceTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            staff_id INTEGER,
            date TEXT,
            time_in_morning TEXT,
            time_out_morning TEXT,
            time_in_afternoon TEXT,
            time_out_afternoon TEXT,
            FOREIGN KEY(staff_id) REFERENCES $staffTable(id)
          )
        ''');
      },
    );
  }

  // Staff CRUD
  Future<int> insertStaff(Map<String, dynamic> staff) async {
    final db = await database;
    return await db.insert(staffTable, staff);
  }

  Future<List<Map<String, dynamic>>> getAllStaff() async {
    final db = await database;
    return await db.query(staffTable);
  }

  Future<int> updateStaff(int id, Map<String, dynamic> staff) async {
    final db = await database;
    return await db.update(staffTable, staff, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteStaff(int id) async {
    final db = await database;
    return await db.delete(staffTable, where: 'id = ?', whereArgs: [id]);
  }

  // Insert or update staff by id_number (for sync)
  Future<int> insertOrUpdateStaff(Map<String, dynamic> staff) async {
    final db = await database;
    final idNumber = staff['id_number'];

    // Check if staff already exists
    final existing = await db.query(
      staffTable,
      where: 'id_number = ?',
      whereArgs: [idNumber],
    );

    if (existing.isNotEmpty) {
      // Update existing
      return await db.update(
        staffTable,
        staff,
        where: 'id_number = ?',
        whereArgs: [idNumber],
      );
    } else {
      // Insert new
      return await db.insert(staffTable, staff);
    }
  }

  // Attendance CRUD
  Future<int> insertAttendance(Map<String, dynamic> attendance) async {
    final db = await database;
    return await db.insert(attendanceTable, attendance);
  }

  Future<List<Map<String, dynamic>>> getAttendanceByStaff(int staffId) async {
    final db = await database;
    return await db.query(
      attendanceTable,
      where: 'staff_id = ?',
      whereArgs: [staffId],
    );
  }

  Future<int> updateAttendance(int id, Map<String, dynamic> attendance) async {
    final db = await database;
    return await db.update(
      attendanceTable,
      attendance,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAttendance(int id) async {
    final db = await database;
    return await db.delete(attendanceTable, where: 'id = ?', whereArgs: [id]);
  }

  // Get all attendance records for a specific date (for homepage display)
  Future<List<Map<String, dynamic>>> getAttendanceByDate(String date) async {
    final db = await database;
    return await db.query(
      attendanceTable,
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  // Get staff with their attendance for a specific date (joined query)
  Future<List<Map<String, dynamic>>> getStaffWithAttendanceByDate(
    String date,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT s.*, a.* FROM $staffTable s
      LEFT JOIN $attendanceTable a ON s.id = a.staff_id AND a.date = ?
      ORDER BY COALESCE(a.time_in_afternoon, a.time_in_morning) DESC
    ''',
      [date],
    );
    return result;
  }
}
