import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentLog {
  final String? lrn;
  final String fullName;
  final String yearAndSection;
  final String address;
  final String emergencyContact;
  final String date;
  final DateTime? morningIn;
  final DateTime? morningOut;
  final DateTime? afternoonIn;
  final DateTime? afternoonOut;

  StudentLog({
    this.lrn,
    required this.fullName,
    required this.yearAndSection,
    required this.address,
    required this.emergencyContact,
    required this.date,
    this.morningIn,
    this.morningOut,
    this.afternoonIn,
    this.afternoonOut,
  });

  /// Check if student is currently inside campus
  bool get isInsideCampus {
    // Morning session: scanned in but not out
    if (morningIn != null && morningOut == null) return true;
    // Afternoon session: scanned in but not out
    if (afternoonIn != null && afternoonOut == null) return true;
    return false;
  }

  /// Check if student was late (after 7:30 AM)
  bool get wasLate {
    if (morningIn == null) return false;
    final officialStartTime = DateTime(
      morningIn!.year,
      morningIn!.month,
      morningIn!.day,
      7,
      30,
    );
    return morningIn!.isAfter(officialStartTime);
  }

  /// Get attendance status
  String get attendanceStatus {
    if (isInsideCampus) return 'Inside Campus';
    if (morningIn != null || afternoonIn != null) return 'Present';
    return 'Absent';
  }

  /// Format time for display
  static String formatTime(DateTime? time, BuildContext context) {
    if (time == null) return 'N/A';
    return TimeOfDay.fromDateTime(time).format(context);
  }

  /// Format time without context (using intl)
  String formatTimeString(DateTime? time) {
    if (time == null) return 'N/A';
    return DateFormat('hh:mm a').format(time);
  }

  /// Create StudentLog from Firestore document
  factory StudentLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentLog.fromMap(data, doc.id);
  }

  /// Create StudentLog from Map
  factory StudentLog.fromMap(Map<String, dynamic> map, [String? docId]) {
    return StudentLog(
      lrn: docId ?? map['lrn'],
      fullName: map['fullName'] ?? 'N/A',
      yearAndSection: map['yearAndSection'] ?? 'N/A',
      address: map['address'] ?? 'N/A',
      emergencyContact: map['emergencyContact'] ?? 'N/A',
      date: map['date'] ?? '',
      morningIn: _parseTimestamp(map['morningIn']),
      morningOut: _parseTimestamp(map['morningOut']),
      afternoonIn: _parseTimestamp(map['afternoonIn']),
      afternoonOut: _parseTimestamp(map['afternoonOut']),
    );
  }

  /// Parse Firestore Timestamp to DateTime
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Convert StudentLog to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'yearAndSection': yearAndSection,
      'address': address,
      'emergencyContact': emergencyContact,
      'date': date,
      'morningIn': morningIn != null ? Timestamp.fromDate(morningIn!) : null,
      'morningOut': morningOut != null ? Timestamp.fromDate(morningOut!) : null,
      'afternoonIn': afternoonIn != null
          ? Timestamp.fromDate(afternoonIn!)
          : null,
      'afternoonOut': afternoonOut != null
          ? Timestamp.fromDate(afternoonOut!)
          : null,
    };
  }

  /// Create a copy with modified fields
  StudentLog copyWith({
    String? lrn,
    String? fullName,
    String? yearAndSection,
    String? address,
    String? emergencyContact,
    String? date,
    DateTime? morningIn,
    DateTime? morningOut,
    DateTime? afternoonIn,
    DateTime? afternoonOut,
  }) {
    return StudentLog(
      lrn: lrn ?? this.lrn,
      fullName: fullName ?? this.fullName,
      yearAndSection: yearAndSection ?? this.yearAndSection,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      date: date ?? this.date,
      morningIn: morningIn ?? this.morningIn,
      morningOut: morningOut ?? this.morningOut,
      afternoonIn: afternoonIn ?? this.afternoonIn,
      afternoonOut: afternoonOut ?? this.afternoonOut,
    );
  }

  @override
  String toString() {
    return 'StudentLog(lrn: $lrn, fullName: $fullName, date: $date, status: $attendanceStatus)';
  }
}
