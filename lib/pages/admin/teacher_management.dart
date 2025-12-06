import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';
import '../../services/excel_import_service.dart';

class TeacherManagement extends StatefulWidget {
  const TeacherManagement({super.key});

  @override
  State<TeacherManagement> createState() => _TeacherManagementState();
}

class _TeacherManagementState extends State<TeacherManagement> {
  List<Teacher> _allTeachers = [];
  List<Teacher> _filteredTeachers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Theme colors
  static const Color _primaryBlue = Color(0xFF1E3A8A);
  static const Color _mediumBlue = Color(0xFF3B82F6);
  static const Color _lightBlue = Color(0xFF60A5FA);

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      final teachers = await FirebaseService.getAllTeachers();
      teachers.sort((a, b) => a.fullname.compareTo(b.fullname));

      setState(() {
        _allTeachers = teachers;
        _filteredTeachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading teachers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterTeachers(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredTeachers = _allTeachers;
      } else {
        _filteredTeachers = _allTeachers.where((teacher) {
          return teacher.fullname.toLowerCase().contains(_searchQuery) ||
              teacher.lrn.toLowerCase().contains(_searchQuery) ||
              (teacher.department?.toLowerCase().contains(_searchQuery) ??
                  false);
        }).toList();
      }
    });
  }

  Future<void> _importExcel() async {
    await importExcelAndUploadToFirebase('teacher');
    _loadTeachers(); // Reload after import
  }

  Future<void> _deleteTeacher(Teacher teacher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Teacher'),
        content: Text('Are you sure you want to delete ${teacher.fullname}?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseService.deleteTeacher(teacher.lrn);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${teacher.fullname} deleted successfully')),
        );
        _loadTeachers();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting teacher: $e')));
      }
    }
  }

  Future<void> _showAddTeacherDialog() async {
    final formKey = GlobalKey<FormState>();
    final lrnController = TextEditingController();
    final fullnameController = TextEditingController();
    final departmentController = TextEditingController();
    final positionController = TextEditingController();
    final addressController = TextEditingController();
    final emergencyContactController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_add,
                color: _primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Add New Teacher'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    controller: lrnController,
                    label: 'Employee ID',
                    icon: Icons.badge,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Employee ID is required';
                      }
                      // Check if Employee ID already exists
                      if (_allTeachers.any((t) => t.lrn == value.trim())) {
                        return 'Employee ID already exists';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: fullnameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: departmentController,
                    label: 'Department (Optional)',
                    icon: Icons.business,
                    isRequired: false,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: positionController,
                    label: 'Position (Optional)',
                    icon: Icons.work,
                    isRequired: false,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: addressController,
                    label: 'Address (Optional)',
                    icon: Icons.location_on,
                    isRequired: false,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: emergencyContactController,
                    label: 'Emergency Contact (Optional)',
                    icon: Icons.phone,
                    isRequired: false,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Teacher'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final teacherData = {
          'lrn': lrnController.text.trim(),
          'fullname': fullnameController.text.trim(),
          'department': departmentController.text.trim().isNotEmpty
              ? departmentController.text.trim()
              : null,
          'position': positionController.text.trim().isNotEmpty
              ? positionController.text.trim()
              : null,
          'address': addressController.text.trim().isNotEmpty
              ? addressController.text.trim()
              : null,
          'emergency_contact': emergencyContactController.text.trim().isNotEmpty
              ? emergencyContactController.text.trim()
              : null,
        };

        await FirebaseService.addTeacherDataFromMap(teacherData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fullnameController.text} added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTeachers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding teacher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Dispose controllers
    lrnController.dispose();
    fullnameController.dispose();
    departmentController.dispose();
    positionController.dispose();
    addressController.dispose();
    emergencyContactController.dispose();
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isRequired,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryBlue, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primaryBlue),
                  )
                : _buildContent(),
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
                          'Teacher Management',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Manage teacher records',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildHeaderButton(
                      icon: Icons.file_upload,
                      label: 'Import Excel',
                      onTap: _importExcel,
                    ),
                    const SizedBox(width: 10),
                    _buildHeaderButton(
                      icon: Icons.add,
                      label: 'Add Teacher',
                      onTap: _showAddTeacherDialog,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
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
                onChanged: _filterTeachers,
                decoration: InputDecoration(
                  hintText: 'Search by name, Employee ID, or department...',
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
                            _filterTeachers('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
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

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              _buildStatCard(
                title: 'Total Teachers',
                value: '${_allTeachers.length}',
                icon: Icons.people,
                color: _mediumBlue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Showing',
                value: '${_filteredTeachers.length}',
                icon: Icons.filter_list,
                color: Colors.green,
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
                          'Showing ${_filteredTeachers.length} of ${_allTeachers.length} teachers',
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
                    child: _filteredTeachers.isEmpty
                        ? _buildEmptyState()
                        : _buildDataTable(),
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
                : 'No teachers found',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Import an Excel file or add teachers manually',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
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
                  DataColumn(label: Text('DEPARTMENT')),
                  DataColumn(label: Text('POSITION')),
                  DataColumn(label: Text('ADDRESS')),
                  DataColumn(label: Text('EMERGENCY CONTACT')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: _filteredTeachers
                    .map((teacher) => _buildDataRow(teacher))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(Teacher teacher) {
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
                    teacher.fullname.isNotEmpty
                        ? teacher.fullname[0].toUpperCase()
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
                teacher.fullname,
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
              teacher.lrn,
              style: const TextStyle(
                color: _primaryBlue,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            teacher.department ?? 'N/A',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        DataCell(
          Text(
            teacher.position ?? 'N/A',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        DataCell(
          Text(
            teacher.address ?? 'N/A',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        DataCell(
          Text(
            teacher.emergencyContact ?? 'N/A',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: _mediumBlue,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit coming soon!')),
                  );
                },
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red.shade400,
                onPressed: () => _deleteTeacher(teacher),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
