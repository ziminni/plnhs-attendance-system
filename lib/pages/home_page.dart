import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../services/local_db_service.dart';
import '../models/models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  AppUser? _currentUser;
  bool _isLoading = true;
  int _selectedTab = 0; // 0 = Students, 1 = Teachers
  List<StudentLog> _recentStudentLogs = [];
  List<TeacherLog> _recentTeacherLogs = [];
  List<StudentLog> _filteredStudentLogs = [];
  List<TeacherLog> _filteredTeacherLogs = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Theme colors
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _mediumBlue = Color(0xFF3B82F6);
  static const Color _lightBlue = Color(0xFF60A5FA);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final firebaseService = FirebaseService();
      final user = await firebaseService.getCurrentAppUser();

      // Get today's date for logs
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Get all staff with their attendance from local database
      final localDbService = LocalDbService();
      final staffWithAttendance = await localDbService
          .getStaffWithAttendanceByDate(today);

      // Build StudentLog and TeacherLog objects from local database
      final studentLogs = <StudentLog>[];
      final teacherLogs = <TeacherLog>[];

      for (final record in staffWithAttendance) {
        // Skip records with no attendance data
        if (record['time_in_morning'] == null &&
            record['time_in_afternoon'] == null) {
          continue;
        }

        final fullName = record['fullname'] ?? 'Unknown';
        final lrn = record['id_number'] ?? '';

        // Parse datetime fields
        DateTime? morningIn;
        DateTime? morningOut;
        DateTime? afternoonIn;
        DateTime? afternoonOut;

        if (record['time_in_morning'] != null) {
          morningIn = DateTime.parse(record['time_in_morning']);
        }
        if (record['time_out_morning'] != null) {
          morningOut = DateTime.parse(record['time_out_morning']);
        }
        if (record['time_in_afternoon'] != null) {
          afternoonIn = DateTime.parse(record['time_in_afternoon']);
        }
        if (record['time_out_afternoon'] != null) {
          afternoonOut = DateTime.parse(record['time_out_afternoon']);
        }

        // Query Firebase to determine if user is teacher or student
        final isStudent = await FirebaseService.getStudentByLrn(lrn) != null;
        final isTeacher = await FirebaseService.getTeacherByLrn(lrn) != null;

        if (isStudent) {
          studentLogs.add(
            StudentLog(
              lrn: lrn,
              fullName: fullName,
              yearAndSection: 'Unknown',
              address: 'Unknown',
              emergencyContact: 'Unknown',
              date: today,
              morningIn: morningIn,
              morningOut: morningOut,
              afternoonIn: afternoonIn,
              afternoonOut: afternoonOut,
            ),
          );
        } else if (isTeacher) {
          teacherLogs.add(
            TeacherLog(
              lrn: lrn,
              fullName: fullName,
              address: 'Unknown',
              emergencyContact: 'Unknown',
              date: today,
              morningIn: morningIn,
              morningOut: morningOut,
              afternoonIn: afternoonIn,
              afternoonOut: afternoonOut,
            ),
          );
        }
      }

      // Sort by most recent (latest timestamp)
      studentLogs.sort((a, b) {
        final aTime =
            a.afternoonOut ?? a.afternoonIn ?? a.morningOut ?? a.morningIn;
        final bTime =
            b.afternoonOut ?? b.afternoonIn ?? b.morningOut ?? b.morningIn;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      teacherLogs.sort((a, b) {
        final aTime =
            a.afternoonOut ?? a.afternoonIn ?? a.morningOut ?? a.morningIn;
        final bTime =
            b.afternoonOut ?? b.afternoonIn ?? b.morningOut ?? b.morningIn;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _currentUser = user;
        _recentStudentLogs = studentLogs;
        _recentTeacherLogs = teacherLogs;
        _filteredStudentLogs = studentLogs;
        _filteredTeacherLogs = teacherLogs;
        _isLoading = false;
      });

      print(
        '✅ Loaded ${studentLogs.length} students and ${teacherLogs.length} teachers from local database',
      );
    } catch (e) {
      print('❌ Error loading home data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryBlue, _mediumBlue, _lightBlue.withOpacity(0.8)],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _buildHeader(),
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildTabSwitch(),
                                const SizedBox(height: 12),
                                _buildSearchBar(),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _selectedTab == 0
                                      ? _buildStudentList()
                                      : _buildTeacherList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final greeting = _getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _currentUser?.displayName ?? 'Guard',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(now),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning 👋';
    } else if (hour < 17) {
      return 'Good Afternoon 👋';
    } else {
      return 'Good Evening 👋';
    }
  }

  void _filterLogs(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredStudentLogs = _recentStudentLogs;
        _filteredTeacherLogs = _recentTeacherLogs;
      } else {
        _filteredStudentLogs = _recentStudentLogs.where((log) {
          return log.fullName.toLowerCase().contains(_searchQuery) ||
              (log.lrn?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();
        _filteredTeacherLogs = _recentTeacherLogs.where((log) {
          return log.fullName.toLowerCase().contains(_searchQuery) ||
              (log.lrn?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();
      }
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterLogs,
          decoration: InputDecoration(
            hintText: _selectedTab == 0
                ? 'Search students by name or LRN...'
                : 'Search teachers by name or ID...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade500,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterLogs('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0
                        ? _primaryBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school,
                        size: 18,
                        color: _selectedTab == 0
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Students',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 0
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_filteredStudentLogs.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1
                        ? _primaryBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        size: 18,
                        color: _selectedTab == 1
                            ? Colors.white
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Teachers',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedTab == 1
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_filteredTeacherLogs.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    if (_recentStudentLogs.isEmpty) {
      return _buildEmptyState('No student logs today');
    }

    if (_filteredStudentLogs.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptyState('No students match "$_searchQuery"');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filteredStudentLogs.length,
        itemBuilder: (context, index) {
          final log = _filteredStudentLogs[index];
          return _buildStudentLogCard(log);
        },
      ),
    );
  }

  Widget _buildTeacherList() {
    if (_recentTeacherLogs.isEmpty) {
      return _buildEmptyState('No teacher logs today');
    }

    if (_filteredTeacherLogs.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptyState('No teachers match "$_searchQuery"');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filteredTeacherLogs.length,
        itemBuilder: (context, index) {
          final log = _filteredTeacherLogs[index];
          return _buildTeacherLogCard(log);
        },
      ),
    );
  }

  Widget _buildStudentLogCard(StudentLog log) {
    final latestTime = _getLatestTime(
      log.morningIn,
      log.morningOut,
      log.afternoonIn,
      log.afternoonOut,
    );
    final latestType = _getLatestType(
      log.morningIn,
      log.morningOut,
      log.afternoonIn,
      log.afternoonOut,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_mediumBlue, _lightBlue]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                log.fullName.isNotEmpty ? log.fullName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'LRN: ${log.lrn}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Time & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(latestType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  latestType,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(latestType),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                latestTime,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherLogCard(TeacherLog log) {
    final latestTime = _getLatestTime(
      log.morningIn,
      log.morningOut,
      log.afternoonIn,
      log.afternoonOut,
    );
    final latestType = _getLatestType(
      log.morningIn,
      log.morningOut,
      log.afternoonIn,
      log.afternoonOut,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade300],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                log.fullName.isNotEmpty ? log.fullName[0].toUpperCase() : 'T',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'ID: ${log.lrn}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Time & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(latestType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  latestType,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(latestType),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                latestTime,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan QR codes to see attendance logs here',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _getLatestTime(
    DateTime? morningIn,
    DateTime? morningOut,
    DateTime? afternoonIn,
    DateTime? afternoonOut,
  ) {
    DateTime? latest;
    if (afternoonOut != null)
      latest = afternoonOut;
    else if (afternoonIn != null)
      latest = afternoonIn;
    else if (morningOut != null)
      latest = morningOut;
    else if (morningIn != null)
      latest = morningIn;

    if (latest == null) return '--:--';
    return DateFormat('h:mm a').format(latest);
  }

  String _getLatestType(
    DateTime? morningIn,
    DateTime? morningOut,
    DateTime? afternoonIn,
    DateTime? afternoonOut,
  ) {
    if (afternoonOut != null) return 'PM OUT';
    if (afternoonIn != null) return 'PM IN';
    if (morningOut != null) return 'AM OUT';
    if (morningIn != null) return 'AM IN';
    return 'N/A';
  }

  Color _getStatusColor(String type) {
    switch (type) {
      case 'AM IN':
        return Colors.green;
      case 'AM OUT':
        return Colors.orange;
      case 'PM IN':
        return Colors.blue;
      case 'PM OUT':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
