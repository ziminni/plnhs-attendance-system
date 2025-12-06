import 'package:flutter/material.dart';

/// Enum representing the different types of attendance
enum AttendanceType {
  morningIn('morning_in', 'Morning IN', Icons.wb_sunny_outlined),
  morningOut('morning_out', 'Morning OUT', Icons.wb_sunny),
  afternoonIn('afternoon_in', 'Afternoon IN', Icons.brightness_3_outlined),
  afternoonOut('afternoon_out', 'Afternoon OUT', Icons.brightness_3);

  final String value;
  final String displayName;
  final IconData icon;

  const AttendanceType(this.value, this.displayName, this.icon);

  /// Get color for attendance type
  Color get color {
    switch (this) {
      case AttendanceType.morningIn:
        return Colors.orange;
      case AttendanceType.morningOut:
        return Colors.orange.shade700;
      case AttendanceType.afternoonIn:
        return Colors.blue;
      case AttendanceType.afternoonOut:
        return Colors.blue.shade700;
    }
  }

  /// Get AttendanceType from string value
  static AttendanceType fromString(String value) {
    return AttendanceType.values.firstWhere(
      (type) =>
          type.value == value.toLowerCase() ||
          type.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => AttendanceType.morningIn,
    );
  }

  /// Get the Firestore field name for this attendance type
  String get firestoreField {
    switch (this) {
      case AttendanceType.morningIn:
        return 'morningIn';
      case AttendanceType.morningOut:
        return 'morningOut';
      case AttendanceType.afternoonIn:
        return 'afternoonIn';
      case AttendanceType.afternoonOut:
        return 'afternoonOut';
    }
  }
}
