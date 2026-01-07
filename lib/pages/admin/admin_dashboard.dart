// Replace the entire admin_dashboard.dart with this corrected version:

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'teachers_logs.dart';
import 'students_logs.dart';
import 'teacher_management.dart';
import 'student_management.dart';
import 'archive_logs.dart';

import '/services/firebase_service.dart';

// Import the models directly to avoid the error
import '/models/student_model.dart' as student_model;
import '/models/teacher_model.dart' as teacher_model;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // Dashboard statistics
  int _studentsInsideCampus = 0;
  int _studentsEnteredToday = 0;
  int _studentsLeftToday = 0;
  int _lateStudentsToday = 0;
  bool _isLoading = false;

  // List of widget options for the dashboard
  final List<Widget> _widgetOptions = [
    const DashboardHome(),
    const TeachersLogs(),
    const StudentsLogs(),
    const TeacherManagement(),
    const StudentManagement(),
    const ArchiveLogs(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Get all student logs for today - now returns List<StudentLog>
      final logs = await FirebaseService.getStudentLogsByDate(todayDate);

      // Calculate metrics using StudentLog model
      int insideCampus = 0;
      int enteredToday = 0;
      int leftToday = 0;
      int lateStudents = 0;

      for (var log in logs) {
        // Use the model's built-in properties
        if (log.isInsideCampus) {
          insideCampus++;
        }

        // Count total entries for today
        if (log.morningIn != null) enteredToday++;
        if (log.afternoonIn != null) enteredToday++;

        // Count total exits for today
        if (log.morningOut != null) leftToday++;
        if (log.afternoonOut != null) leftToday++;

        // Check for late students using the model's wasLate property
        if (log.wasLate) {
          lateStudents++;
        }
      }

      setState(() {
        _studentsInsideCampus = insideCampus;
        _studentsEnteredToday = enteredToday;
        _studentsLeftToday = leftToday;
        _lateStudentsToday = lateStudents;
        _isLoading = false;
      });
    } catch (error) {
      developer.log('Error fetching dashboard data: $error', name: 'AdminDashboard');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildTitleBar(BuildContext context) {
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Menu button
            _buildHeaderIconButton(
              icon: Icons.menu,
              tooltip: 'Menu',
              onTap: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 12),
            // Logo and title
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            // E.A.R.L.Y Title
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFFE3F2FD)],
              ).createShader(bounds),
              child: const Text(
                'E.A.R.L.Y',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            // Time display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: const Color(0xFFFFFFFF).withOpacity(0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('hh:mm a').format(now),
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFFFFFFF).withOpacity(0.95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            // Refresh button
            _buildHeaderIconButton(
              icon: Icons.refresh,
              tooltip: 'Refresh Data',
              onTap: () => setState(() {}),
            ),
            const SizedBox(width: 8),
            // Logout button
            _buildHeaderIconButton(
              icon: Icons.logout,
              tooltip: 'Sign Out',
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFFFFFFF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            // Title Bar with E.A.R.L.Y
            _buildTitleBar(context),
            // Content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF)),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _widgetOptions.elementAt(_selectedIndex),
              ),
            ),
          ],
        ),
      ),
      drawer: _buildSidebar(),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A), // Royal blue dark
              Color(0xFF3B82F6), // Royal blue medium
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'ADMIN PANEL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Last sync: ${DateFormat('hh:mm a').format(DateTime.now())}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            _buildMenuItem(
              index: 0,
              icon: Icons.dashboard,
              title: 'Dashboard',
              isSelected: _selectedIndex == 0,
            ),
            const Divider(color: Colors.white24, height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'ATTENDANCE LOGS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
            _buildMenuItem(
              index: 1,
              icon: Icons.people,
              title: 'Teacher Logs',
              isSelected: _selectedIndex == 1,
            ),
            _buildMenuItem(
              index: 2,
              icon: Icons.school,
              title: 'Student Logs',
              isSelected: _selectedIndex == 2,
            ),
            const Divider(color: Colors.white24, height: 1),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'DATA MANAGEMENT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
            _buildMenuItem(
              index: 3,
              icon: Icons.person_add,
              title: 'Teacher Management',
              isSelected: _selectedIndex == 3,
            ),
            _buildMenuItem(
              index: 4,
              icon: Icons.child_care,
              title: 'Student Management',
              isSelected: _selectedIndex == 4,
            ),
            _buildMenuItem(
              index: 5,
              icon: Icons.archive,
              title: 'Archive Logs',
              isSelected: _selectedIndex == 5,
            ),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DATA STATUS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDataStatus(
                    'Total Students Inside',
                    _studentsInsideCampus,
                  ),
                  _buildDataStatus(
                    'Students Entered Today',
                    _studentsEnteredToday,
                  ),
                  _buildDataStatus('Students Left Today', _studentsLeftToday),
                  _buildDataStatus('Late Arrivals', _lateStudentsToday),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String title,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFFFFF).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFFFFFFFF).withOpacity(0.7),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : const Color(0xFFFFFFFF).withOpacity(0.9),
          ),
        ),
        onTap: () => _onItemTapped(index),
      ),
    );
  }

  Widget _buildDataStatus(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dashboard Home Widget with clean, focused design
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _startClockTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Trigger rebuild to update time
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final formattedTime = DateFormat('hh:mm:ss a').format(now);
    final todayDateStr = DateFormat('yyyy-MM-dd').format(now);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, size: 40, color: Colors.white),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CAMPUS SECURITY MONITORING',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFFFFFFFF).withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Early Risers section (moved to top)
            StreamBuilder<EarlyRiserResults>(
              stream: FirebaseService.getEarlyRisersStream(days: 30),
              builder: (context, snapshot) {
                final results = snapshot.data;
                final students = results?.students.take(5).toList() ?? [];
                final teachers = results?.teachers.take(5).toList() ?? [];

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.wb_sunny,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Top Early Risers (Last 30 Days)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 14, color: Colors.orange),
                                SizedBox(width: 6),
                                Text(
                                  'Arrivals before 6:30 AM',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildEarlyRiserCard(
                              '🏆 Top Early Students',
                              students,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildEarlyRiserCard(
                              '👨‍🏫 Top Early Teachers',
                              teachers,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Real-time Statistics Cards
            StreamBuilder<DashboardMetrics>(
              stream: FirebaseService.getDashboardMetricsStream(),
              builder: (context, snapshot) {
                final metrics =
                    snapshot.data ??
                        DashboardMetrics(
                          studentsInsideCampus: 0,
                          studentsEnteredToday: 0,
                          studentsLeftToday: 0,
                          lateStudentsToday: 0,
                        );

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(
                      title: 'STUDENTS INSIDE CAMPUS',
                      value: metrics.studentsInsideCampus.toString(),
                      subtitle: 'Currently Present',
                      icon: Icons.person_pin_circle,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFFDC2626), // Red for critical
                      borderColor: const Color(0xFFEF4444),
                      tooltip:
                          'Students who scanned IN but have not scanned OUT yet',
                    ),
                    _buildStatCard(
                      title: 'ENTERED TODAY',
                      value: metrics.studentsEnteredToday.toString(),
                      subtitle: 'Total IN Scans',
                      icon: Icons.login,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFF2563EB), // Blue
                      borderColor: const Color(0xFF3B82F6),
                      tooltip: 'Total number of "IN" scans for the day',
                    ),
                    _buildStatCard(
                      title: 'LEFT TODAY',
                      value: metrics.studentsLeftToday.toString(),
                      subtitle: 'Total OUT Scans',
                      icon: Icons.logout,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFF059669), // Green
                      borderColor: const Color(0xFF10B981),
                      tooltip: 'How many students scanned OUT today',
                    ),
                    _buildStatCard(
                      title: 'LATE ARRIVALS',
                      value: metrics.lateStudentsToday.toString(),
                      subtitle: 'After 7:30 AM',
                      icon: Icons.access_time,
                      iconColor: Colors.white,
                      backgroundColor: const Color(0xFFD97706), // Amber
                      borderColor: const Color(0xFFF59E0B),
                      tooltip:
                          'Students who entered after official time (7:30 AM)',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),

            // New Section: Attendance Issues
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.warning,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Attendance Issues',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.refresh, size: 14, color: Colors.red),
                            SizedBox(width: 6),
                            Text(
                              'Auto-refresh every 5s',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Row with three tables
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Absent Students
                      Expanded(
                        child: StreamBuilder<List<student_model.Student>>(
                          stream: FirebaseService.getAbsentStudentsStream(todayDateStr),
                          builder: (context, snapshot) {
                            final absentStudents = snapshot.data ?? [];
                            return _buildAttendanceIssueCard(
                              '👨‍🎓 Absent Students',
                              'Total: ${absentStudents.length}',
                              Icons.person_off,
                              Colors.red,
                              absentStudents.map((student) => {
                                'id': student.lrn,
                                'name': student.fullName,
                                'info': student.gradeAndSection ?? 'No Section',
                              }).toList(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      // Absent Teachers
                      Expanded(
                        child: StreamBuilder<List<teacher_model.Teacher>>(
                          stream: FirebaseService.getAbsentTeachersStream(todayDateStr),
                          builder: (context, snapshot) {
                            final absentTeachers = snapshot.data ?? [];
                            return _buildAttendanceIssueCard(
                              '👨‍🏫 Absent Teachers',
                              'Total: ${absentTeachers.length}',
                              Icons.person_off_outlined,
                              Colors.orange,
                              absentTeachers.map((teacher) => {
                                'id': teacher.lrn,
                                'name': teacher.fullname,
                                'info': teacher.department ?? 'No Department',
                              }).toList(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      // Incomplete Logs
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: FirebaseService.getIncompleteLogsStream(todayDateStr),
                          builder: (context, snapshot) {
                            final incompleteLogs = snapshot.data ?? [];
                            return _buildIncompleteLogsCard(incompleteLogs);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Live Update Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.update, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Data Updates',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated: ${DateFormat('hh:mm:ss a').format(DateTime.now())}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Information Panel
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700], size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'How Metrics Are Calculated',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoItem(
                    'Students Inside Campus',
                    'Counts students who scanned IN but have not scanned OUT yet. This includes both morning and afternoon sessions.',
                  ),
                  _buildInfoItem(
                    'Late Arrivals',
                    'Students who scanned IN after 7:30 AM in the morning session. Afternoon arrivals are not counted as late.',
                  ),
                  _buildInfoItem(
                    'Absent Tracking',
                    'Users without any IN scans for the day are marked as absent. Lists update automatically every 5 seconds.',
                  ),
                  _buildInfoItem(
                    'Incomplete Logs',
                    'Users who scanned IN but missed OUT scans, or scanned OUT but missed subsequent IN scans.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    String tooltip = '',
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundColor, backgroundColor.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: iconColor),
                  ),
                  if (title == 'STUDENTS INSIDE CAMPUS' && int.parse(value) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFFFFF).withOpacity(0.9),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFFFFFFFF).withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarlyRiserCard(String title, List<EarlyRiser> list) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No early arrivals in the selected period.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${item.id}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.earlyCount} days',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            Text(
                              '${item.points} pts',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceIssueCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<Map<String, dynamic>> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 40, color: Colors.green.shade300),
                    const SizedBox(height: 8),
                    const Text(
                      'All Present',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${item['id']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item['info'],
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIncompleteLogsCard(List<Map<String, dynamic>> incompleteLogs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber, size: 20, color: Colors.orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Incomplete Logs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    Text(
                      'Total: ${incompleteLogs.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (incompleteLogs.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 40, color: Colors.green.shade300),
                    const SizedBox(height: 8),
                    const Text(
                      'All Complete',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: incompleteLogs.length,
                itemBuilder: (context, index) {
                  final log = incompleteLogs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: log['type'] == 'Student'
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              log['type'] == 'Student' ? 'S' : 'T',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: log['type'] == 'Student'
                                    ? Colors.blue
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${log['id']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: (log['issues'] as List<String>)
                                    .map((issue) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: Colors.red.shade100,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            issue,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.red.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}