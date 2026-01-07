import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/local_db_service.dart';
import '../models/models.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppUser? _currentUser;
  bool _isLoading = true;
  DateTime? _lastSyncTime;
  DateTime? _lastUploadTime;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await FirebaseService().getCurrentAppUser();
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your account and preferences',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Profile Card
                      _buildProfileCard(),
                      const SizedBox(height: 20),

                      // Sync and Upload Buttons
                      _buildSyncUploadButtons(),
                      const SizedBox(height: 20),

                      // Account Info Card
                      _buildAccountInfoCard(),
                      const SizedBox(height: 20),

                      // App Info Card
                      _buildAppInfoCard(),
                      const SizedBox(height: 30),

                      // Sign Out Button
                      _buildSignOutButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSyncUploadButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _syncStaffData,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'Sync',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _lastSyncTime == null
                        ? 'Never'
                        : _formatTimeAgo(_lastSyncTime!),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _syncAttendanceToFirebase,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _lastUploadTime == null
                        ? 'Never'
                        : _formatTimeAgo(_lastUploadTime!),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.security, size: 40, color: Colors.white),
            ),
            const SizedBox(width: 20),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser?.displayName ?? 'Guard',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _currentUser?.role.value.toUpperCase() ?? 'STAFF',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_circle, color: Colors.blue.shade600),
                const SizedBox(width: 10),
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              icon: Icons.badge,
              label: 'User ID',
              value: user?.uid.substring(0, 12) ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: user?.email ?? 'N/A',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.work,
              label: 'Role',
              value: _currentUser?.role.value ?? 'Staff',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Last Login',
              value: _formatDateTime(_currentUser?.lastLogin),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Account Created',
              value: _formatDateTime(_currentUser?.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.blue.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 10),
                const Text(
                  'App Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              icon: Icons.apps,
              label: 'App Name',
              value: 'E.A.R.L.Y Attendance System',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.new_releases,
              label: 'Version',
              value: '1.0.0',
            ),
            const Divider(height: 24),
            _buildInfoRow(icon: Icons.school, label: 'School', value: 'PLNHS'),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout),
        label: const Text(
          'Sign Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return _formatDateTime(dateTime);
    }
  }

  Future<void> _syncStaffData() async {
    log('🔄 Starting staff data sync from Firebase...');

    // Check internet connection
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('No internet');
      }
    } on SocketException catch (_) {
      log('❌ No internet connection');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No internet connection available'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syncing staff & student data...'),
          duration: Duration(seconds: 2),
        ),
      );

      final dbService = LocalDbService();
      int synced = 0;

      // Fetch all teachers from Firebase
      try {
        log('📥 Fetching teachers...');
        final teachersSnapshot = await FirebaseFirestore.instance
            .collection('teachers')
            .get();
        log('📥 Found ${teachersSnapshot.docs.length} teachers in Firebase');

        for (var doc in teachersSnapshot.docs) {
          try {
            final teacherData = doc.data();
            log('📥 Teacher raw data: $teacherData');
            final lrn = (teacherData['lrn'] ?? doc.id)
                .toString()
                .trim()
                .toLowerCase();

            final fullName =
                teacherData['fullName'] ??
                teacherData['full_name'] ??
                teacherData['name'] ??
                teacherData['fullname'] ??
                'Unknown';
            log(
              '📥 Extracted fullName: "$fullName" from keys: ${teacherData.keys}',
            );

            final staffData = {
              'id_number': lrn,
              'fullname': fullName,
              'phone_number':
                  teacherData['contactNumber'] ??
                  teacherData['contact_number'] ??
                  'N/A',
            };

            await dbService.insertOrUpdateStaff(staffData);
            synced++;
            log('✅ Synced teacher: $lrn - $fullName');
          } catch (e, stackTrace) {
            log('⚠️ Failed to sync teacher: $e\n$stackTrace');
          }
        }
      } catch (e, stackTrace) {
        log('❌ Error fetching teachers: $e\n$stackTrace');
      }

      // Fetch all students from Firebase
      try {
        log('📥 Fetching students...');
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .get();
        log('📥 Found ${studentsSnapshot.docs.length} students in Firebase');

        for (var doc in studentsSnapshot.docs) {
          try {
            final studentData = doc.data();
            log('📥 Student raw data: $studentData');
            final lrn = (studentData['lrn'] ?? doc.id)
                .toString()
                .trim()
                .toLowerCase();

            final fullName =
                studentData['fullName'] ??
                studentData['full_name'] ??
                studentData['name'] ??
                studentData['fullname'] ??
                'Unknown';
            log(
              '📥 Extracted fullName: "$fullName" from keys: ${studentData.keys}',
            );

            final staffData = {
              'id_number': lrn,
              'fullname': fullName,
              'phone_number':
                  studentData['contactNumber'] ??
                  studentData['contact_number'] ??
                  'N/A',
            };

            await dbService.insertOrUpdateStaff(staffData);
            synced++;
            log('✅ Synced student: $lrn - $fullName');
          } catch (e, stackTrace) {
            log('⚠️ Failed to sync student: $e\n$stackTrace');
          }
        }
      } catch (e, stackTrace) {
        log('❌ Error fetching students: $e\n$stackTrace');
      }

      log('✅ Sync completed! $synced total records synced');

      if (mounted) {
        setState(() {
          _lastSyncTime = DateTime.now();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Synced $synced staff & students'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      log('❌ Sync failed: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _syncAttendanceToFirebase() async {
    log('🔄 Starting attendance upload to Firebase...');

    // Check internet connection
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('No internet');
      }
    } on SocketException catch (_) {
      log('❌ No internet connection');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No internet connection available'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading attendance records...'),
          duration: Duration(seconds: 2),
        ),
      );

      final dbService = LocalDbService();
      int uploaded = 0;

      // Get all staff from local DB
      final staffList = await dbService.getAllStaff();
      log('📤 Found ${staffList.length} staff records to sync');

      for (var staff in staffList) {
        try {
          final staffId = staff['id'];
          final lrn = staff['id_number'];
          final fullName = staff['fullname'];

          // Get all attendance records for this staff
          final attendanceRecords = await dbService.getAttendanceByStaff(
            staffId,
          );
          log(
            '📤 Staff $lrn has ${attendanceRecords.length} attendance records',
          );

          // Check if this person is a teacher or student in Firebase
          final isTeacher = await FirebaseService.getTeacherByLrn(lrn) != null;
          final collectionName = isTeacher ? 'teacher_logs' : 'student_logs';
          log(
            '📤 $lrn is a ${isTeacher ? 'TEACHER' : 'STUDENT'} -> uploading to $collectionName',
          );

          for (var record in attendanceRecords) {
            try {
              // Use LRN as document ID (will merge with existing records)
              final docId = lrn;
              log('📤 Uploading to collection: $collectionName, docId: $docId');

              // Prepare attendance data for Firebase
              final attendanceData = {
                'fullName': fullName,
                'lrn': lrn,
                'date': record['date'],
                'morningIn': record['time_in_morning'],
                'morningOut': record['time_out_morning'],
                'afternoonIn': record['time_in_afternoon'],
                'afternoonOut': record['time_out_afternoon'],
              };
              log('📤 Attendance data: $attendanceData');

              // Upload to Firebase - merge with existing data
              await FirebaseFirestore.instance
                  .collection(collectionName)
                  .doc(docId)
                  .set(attendanceData, SetOptions(merge: true));

              uploaded++;
              log('✅ Uploaded to $collectionName/$docId');
            } catch (e, stackTrace) {
              log('⚠️ Failed to upload attendance record: $e\n$stackTrace');
            }
          }
        } catch (e, stackTrace) {
          log('⚠️ Failed to sync attendance for staff: $e\n$stackTrace');
        }
      }

      log('✅ Upload completed! $uploaded attendance records uploaded');

      if (mounted) {
        setState(() {
          _lastUploadTime = DateTime.now();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Uploaded $uploaded attendance records'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      log('❌ Upload failed: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upload failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
