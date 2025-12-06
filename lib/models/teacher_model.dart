import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String lrn; // Employee ID
  final String fullname;
  final String? address;
  final String? emergencyContact;
  final String? department;
  final String? position;

  Teacher({
    required this.lrn,
    required this.fullname,
    this.address,
    this.emergencyContact,
    this.department,
    this.position,
  });

  /// Create Teacher from Firestore document
  factory Teacher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Use document ID as lrn if 'lrn' field is missing or empty
    final lrnFromData = (data['lrn'] ?? '').toString().trim();
    final lrn = lrnFromData.isNotEmpty ? lrnFromData : doc.id;

    return Teacher(
      lrn: lrn.replaceAll(RegExp(r'\s+'), ''),
      fullname: data['fullname'] ?? data['full_name'] ?? data['name'] ?? '',
      address: data['address'],
      emergencyContact: data['emergency_contact'] ?? data['emergencyContact'],
      department: data['department'],
      position: data['position'],
    );
  }

  /// Create Teacher from Map
  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      lrn: (map['lrn'] ?? '').toString().trim().replaceAll(RegExp(r'\s+'), ''),
      fullname: map['fullname'] ?? map['full_name'] ?? map['name'] ?? '',
      address: map['address'],
      emergencyContact: map['emergency_contact'] ?? map['emergencyContact'],
      department: map['department'],
      position: map['position'],
    );
  }

  /// Convert Teacher to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'lrn': lrn,
      'fullname': fullname,
      'address': address,
      'emergency_contact': emergencyContact,
      'department': department,
      'position': position,
    };
  }

  /// Create a copy with modified fields
  Teacher copyWith({
    String? lrn,
    String? fullname,
    String? address,
    String? emergencyContact,
    String? department,
    String? position,
  }) {
    return Teacher(
      lrn: lrn ?? this.lrn,
      fullname: fullname ?? this.fullname,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      department: department ?? this.department,
      position: position ?? this.position,
    );
  }

  @override
  String toString() {
    return 'Teacher(lrn: $lrn, fullname: $fullname, department: $department)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Teacher && other.lrn == lrn;
  }

  @override
  int get hashCode => lrn.hashCode;
}
