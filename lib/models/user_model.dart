import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// User roles for the attendance system
/// - admin: Can access the admin dashboard to view logs and manage data
/// - staff/guard: Can scan QR codes to log attendance
enum UserRole {
  admin('admin'),
  staff('staff'),
  guard('guard'),
  unknown('unknown');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? value) {
    if (value == null) return UserRole.unknown;
    return UserRole.values.firstWhere(
      (role) => role.value.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.unknown,
    );
  }

  /// Check if this role can access the scanner
  bool get canScan => this == UserRole.staff || this == UserRole.guard;

  /// Check if this role can access admin dashboard
  bool get canAccessAdmin => this == UserRole.admin;
}

class AppUser {
  final String uid;
  final String? email;
  final UserRole role;
  final String? displayName;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  AppUser({
    required this.uid,
    this.email,
    required this.role,
    this.displayName,
    this.createdAt,
    this.lastLogin,
  });

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user is staff (guard)
  bool get isStaff => role == UserRole.staff || role == UserRole.guard;

  /// Check if user is guard (alias for isStaff)
  bool get isGuard => isStaff;

  /// Check if user can scan QR codes
  bool get canScan => role.canScan;

  /// Check if user can access admin dashboard
  bool get canAccessAdmin => role.canAccessAdmin;

  /// Create AppUser from Firebase Auth User and Firestore data
  factory AppUser.fromFirebaseUser(
    auth.User firebaseUser,
    Map<String, dynamic>? firestoreData,
  ) {
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      role: UserRole.fromString(firestoreData?['role']),
      displayName: firestoreData?['displayName'] ?? firebaseUser.displayName,
      createdAt: _parseTimestamp(firestoreData?['createdAt']),
      lastLogin: _parseTimestamp(firestoreData?['lastLogin']),
    );
  }

  /// Create AppUser from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'],
      role: UserRole.fromString(data['role']),
      displayName: data['displayName'],
      createdAt: _parseTimestamp(data['createdAt']),
      lastLogin: _parseTimestamp(data['lastLogin']),
    );
  }

  /// Parse Firestore Timestamp to DateTime
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Convert AppUser to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.value,
      'displayName': displayName,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastLogin': lastLogin != null
          ? Timestamp.fromDate(lastLogin!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with modified fields
  AppUser copyWith({
    String? uid,
    String? email,
    UserRole? role,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, role: ${role.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
