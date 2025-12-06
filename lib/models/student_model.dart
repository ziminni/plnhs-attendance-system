import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String lrn;
  final String firstname;
  final String? middlename;
  final String lastname;
  final String? gradeAndSection;
  final String? address;
  final String? guardianContact;

  Student({
    required this.lrn,
    required this.firstname,
    this.middlename,
    required this.lastname,
    this.gradeAndSection,
    this.address,
    this.guardianContact,
  });

  /// Full name combining firstname, middlename, and lastname
  String get fullName {
    final middle = middlename?.isNotEmpty == true ? '$middlename ' : '';
    return '$firstname $middle$lastname'.trim();
  }

  /// Create Student from Firestore document
  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student.fromMap(data);
  }

  /// Create Student from Map
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      lrn: (map['lrn'] ?? '').toString().trim().replaceAll(RegExp(r'\s+'), ''),
      firstname: map['firstname'] ?? '',
      middlename: map['middlename'],
      lastname: map['lastname'] ?? '',
      gradeAndSection: map['grade_and_section'],
      address: map['address'],
      guardianContact: map['guardian_contact'],
    );
  }

  /// Convert Student to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'lrn': lrn,
      'firstname': firstname,
      'middlename': middlename,
      'lastname': lastname,
      'grade_and_section': gradeAndSection,
      'address': address,
      'guardian_contact': guardianContact,
    };
  }

  /// Create a copy with modified fields
  Student copyWith({
    String? lrn,
    String? firstname,
    String? middlename,
    String? lastname,
    String? gradeAndSection,
    String? address,
    String? guardianContact,
  }) {
    return Student(
      lrn: lrn ?? this.lrn,
      firstname: firstname ?? this.firstname,
      middlename: middlename ?? this.middlename,
      lastname: lastname ?? this.lastname,
      gradeAndSection: gradeAndSection ?? this.gradeAndSection,
      address: address ?? this.address,
      guardianContact: guardianContact ?? this.guardianContact,
    );
  }

  @override
  String toString() {
    return 'Student(lrn: $lrn, fullName: $fullName, gradeAndSection: $gradeAndSection)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.lrn == lrn;
  }

  @override
  int get hashCode => lrn.hashCode;
}
