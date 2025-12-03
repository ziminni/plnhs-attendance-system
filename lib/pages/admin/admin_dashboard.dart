import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'teachers_logs.dart';
import 'students_logs.dart';
import 'teacher_management.dart';
import 'student_management.dart';
import 'archive_logs.dart';

import '/services/firebase_service.dart';

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
  bool _isLoading = true;
  
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
    _fetchDashboardData();
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
      
      // Get all student logs for today
      final logs = await FirebaseService.getStudentLogsByDate(todayDate);
      
      // Calculate metrics
      int insideCampus = 0;
      int enteredToday = 0;
      int leftToday = 0;
      int lateStudents = 0;
      
      // Official start time for school (7:30 AM)
      const officialStartTime = TimeOfDay(hour: 7, minute: 30);
      final now = DateTime.now();
      final officialDateTime = DateTime(
        now.year, 
        now.month, 
        now.day, 
        officialStartTime.hour, 
        officialStartTime.minute
      );

      for (var log in logs) {
        final morningIn = log['morningIn'] as Timestamp?;
        final morningOut = log['morningOut'] as Timestamp?;
        final afternoonIn = log['afternoonIn'] as Timestamp?;
        final afternoonOut = log['afternoonOut'] as Timestamp?;

        // Check if student is inside campus (scanned IN but not OUT)
        bool isInside = false;
        
        // Morning session check
        if (morningIn != null && morningOut == null) {
          isInside = true;
        }
        
        // Afternoon session check
        if (afternoonIn != null && afternoonOut == null) {
          isInside = true;
        }
        
        // If student scanned out in morning and hasn't scanned in for afternoon
        if (morningOut != null && afternoonIn == null) {
          final currentTime = TimeOfDay.now();
          if (currentTime.hour >= 12) {
            isInside = false;
          }
        }
        
        if (isInside) {
          insideCampus++;
        }

        // Count total entries for today
        if (morningIn != null) enteredToday++;
        if (afternoonIn != null) enteredToday++;

        // Count total exits for today
        if (morningOut != null) leftToday++;
        if (afternoonOut != null) leftToday++;

        // Check for late students (arrived after 7:30 AM)
        if (morningIn != null) {
          final arrivalTime = morningIn.toDate();
          if (arrivalTime.isAfter(officialDateTime)) {
            lateStudents++;
          }
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
      print('Error fetching dashboard data: $error');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.security, size: 28),
            const SizedBox(width: 10),
            const Text('Campus Security Dashboard'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[900]!.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('hh:mm a').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3A8A), // Royal blue dark
                Color(0xFF3B82F6), // Royal blue medium
                Color(0xFF60A5FA), // Royal blue light
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDashboardData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3B82F6), // Royal blue medium
              Color(0xFFEFF6FF), // Light blue background
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _widgetOptions.elementAt(_selectedIndex),
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
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
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
                  _buildDataStatus('Total Students Inside', _studentsInsideCampus),
                  _buildDataStatus('Students Entered Today', _studentsEnteredToday),
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
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
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
  late _AdminDashboardState parentState;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _startClockTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    parentState = context.findAncestorStateOfType<_AdminDashboardState>()!;
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
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF3B82F6),
                  ],
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
                            color: Colors.white.withOpacity(0.9),
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

            // Real-time Statistics Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  title: 'STUDENTS INSIDE CAMPUS',
                  value: parentState._studentsInsideCampus.toString(),
                  subtitle: 'Currently Present',
                  icon: Icons.person_pin_circle,
                  iconColor: Colors.white,
                  backgroundColor: const Color(0xFFDC2626), // Red for critical
                  borderColor: const Color(0xFFEF4444),
                  tooltip: 'Students who scanned IN but have not scanned OUT yet',
                ),
                _buildStatCard(
                  title: 'ENTERED TODAY',
                  value: parentState._studentsEnteredToday.toString(),
                  subtitle: 'Total IN Scans',
                  icon: Icons.login,
                  iconColor: Colors.white,
                  backgroundColor: const Color(0xFF2563EB), // Blue
                  borderColor: const Color(0xFF3B82F6),
                  tooltip: 'Total number of "IN" scans for the day',
                ),
                _buildStatCard(
                  title: 'LEFT TODAY',
                  value: parentState._studentsLeftToday.toString(),
                  subtitle: 'Total OUT Scans',
                  icon: Icons.logout,
                  iconColor: Colors.white,
                  backgroundColor: const Color(0xFF059669), // Green
                  borderColor: const Color(0xFF10B981),
                  tooltip: 'How many students scanned OUT today',
                ),
                _buildStatCard(
                  title: 'LATE ARRIVALS',
                  value: parentState._lateStudentsToday.toString(),
                  subtitle: 'After 7:30 AM',
                  icon: Icons.access_time,
                  iconColor: Colors.white,
                  backgroundColor: const Color(0xFFD97706), // Amber
                  borderColor: const Color(0xFFF59E0B),
                  tooltip: 'Students who entered after official time (7:30 AM)',
                ),
              ],
            ),

            const SizedBox(height: 40),

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
                  Icon(
                    Icons.update,
                    color: Colors.blue[700],
                    size: 24,
                  ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  colors: [
                    Colors.blue.shade50,
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue[700],
                        size: 24,
                      ),
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
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    'Students Inside Campus',
                    'Counts students who scanned IN but have not scanned OUT yet. This includes both morning and afternoon sessions.',
                  ),
                  _buildInfoItem(
                    'Late Arrivals',
                    'Students who scanned IN after 7:30 AM in the morning session. Afternoon arrivals are not counted as late.',
                  ),
                  _buildInfoItem(
                    'Updates',
                    'Manual refresh is available via the refresh button.',
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
            colors: [
              backgroundColor,
              backgroundColor.withOpacity(0.9),
            ],
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
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 28, color: iconColor),
                  ),
                  if (title == 'STUDENTS INSIDE CAMPUS' && int.parse(value) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
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
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

