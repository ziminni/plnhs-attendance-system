import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';
import '../../services/excel_export_service.dart';

class TeachersLogs extends StatefulWidget {
  const TeachersLogs({super.key});

  @override
  State<TeachersLogs> createState() => _TeachersLogsState();
}

class _TeachersLogsState extends State<TeachersLogs> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Theme colors
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _mediumBlue = Color(0xFF3B82F6);
  static const Color _lightBlue = Color(0xFF60A5FA);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLogs(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  // Stats computed per-build from stream data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<TeacherLog>>(
              stream: FirebaseService.getTeacherLogsStreamByDate(
                DateFormat('yyyy-MM-dd').format(_selectedDate),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryBlue),
                  );
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allLogs = (snapshot.data ?? <TeacherLog>[]).toList();
                allLogs.sort((a, b) => a.fullName.compareTo(b.fullName));

                final filteredLogs = _searchQuery.isEmpty
                    ? allLogs
                    : allLogs.where((log) {
                        return log.fullName.toLowerCase().contains(
                              _searchQuery,
                            ) ||
                            (log.lrn?.toLowerCase().contains(_searchQuery) ??
                                false);
                      }).toList();

                return _buildContentFromLogs(allLogs, filteredLogs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryBlue, _mediumBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Attendance',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Daily attendance logs',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildHeaderButton(
                  icon: Icons.file_download,
                  label: 'Export',
                  onTap: () async {
                    final dateStr = DateFormat(
                      'yyyy-MM-dd',
                    ).format(_selectedDate);
                    final logs = await FirebaseService.getTeacherLogsByDate(
                      dateStr,
                    );
                    if (logs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No data to export')),
                      );
                      return;
                    }
                    try {
                      await ExcelExportService.exportTeacherLogs(
                        logs,
                        _selectedDate,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Export successful!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Export failed: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date Selector & Search
            Row(
              children: [
                // Date Picker
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: _primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat(
                              'EEEE, MMM d, yyyy',
                            ).format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Search
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterLogs,
                      decoration: InputDecoration(
                        hintText: 'Search by name or Employee ID...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterLogs('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentFromLogs(
    List<TeacherLog> allLogs,
    List<TeacherLog> filteredLogs,
  ) {
    final presentCount = allLogs
        .where((log) => log.morningIn != null || log.afternoonIn != null)
        .length;
    final lateCount = allLogs.where((log) => log.wasLate).length;
    final insideCampusCount = allLogs.where((log) => log.isInsideCampus).length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              _buildStatCard(
                title: 'Total Logs',
                value: '${allLogs.length}',
                icon: Icons.people,
                color: _mediumBlue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Present',
                value: '$presentCount',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Late Arrivals',
                value: '$lateCount',
                icon: Icons.access_time,
                color: Colors.red.shade400,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Inside Campus',
                value: '$insideCampusCount',
                icon: Icons.location_on,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${filteredLogs.length} of ${allLogs.length} teachers',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const Spacer(),
                        if (_searchQuery.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _lightBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.filter_list,
                                  size: 16,
                                  color: _primaryBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Filtered by: "$_searchQuery"',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Table Content
                  Expanded(
                    child: filteredLogs.isEmpty
                        ? _buildEmptyState()
                        : _buildDataTableFromLogs(filteredLogs),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No teachers match "$_searchQuery"'
                : 'No attendance logs for this date',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a different date or check back later',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTableFromLogs(List<TeacherLog> logs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                horizontalMargin: 20,
                columnSpacing: 24,
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
                columns: const [
                  DataColumn(label: Text('TEACHER')),
                  DataColumn(label: Text('EMPLOYEE ID')),
                  DataColumn(label: Text('AM IN')),
                  DataColumn(label: Text('AM OUT')),
                  DataColumn(label: Text('PM IN')),
                  DataColumn(label: Text('PM OUT')),
                  DataColumn(label: Text('STATUS')),
                ],
                rows: logs.map((log) => _buildDataRow(log)).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(TeacherLog log) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_mediumBlue, _lightBlue],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    log.fullName.isNotEmpty
                        ? log.fullName[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                log.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _lightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              log.lrn ?? 'N/A',
              style: const TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(_buildTimeCell(log.morningIn, isIn: true)),
        DataCell(_buildTimeCell(log.morningOut, isIn: false)),
        DataCell(_buildTimeCell(log.afternoonIn, isIn: true)),
        DataCell(_buildTimeCell(log.afternoonOut, isIn: false)),
        DataCell(_buildStatusBadge(log)),
      ],
    );
  }

  Widget _buildTimeCell(DateTime? time, {required bool isIn}) {
    if (time == null) {
      return Text('--:--', style: TextStyle(color: Colors.grey.shade400));
    }
    return Text(
      DateFormat('h:mm a').format(time),
      style: TextStyle(
        color: isIn ? Colors.green.shade700 : Colors.orange.shade700,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
    );
  }

  Widget _buildStatusBadge(TeacherLog log) {
    String status;
    Color color;

    if (log.isInsideCampus) {
      status = 'Inside Campus';
      color = Colors.green;
    } else if (log.wasLate) {
      status = 'Late';
      color = Colors.red.shade400;
    } else if (log.morningIn != null || log.afternoonIn != null) {
      status = 'Present';
      color = _mediumBlue;
    } else {
      status = 'No Record';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
