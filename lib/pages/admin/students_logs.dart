import 'package:early_v1_0/services/excel_import_service.dart';
import 'package:early_v1_0/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';

class StudentsLogs extends StatefulWidget {
  const StudentsLogs({super.key});

  @override
  State<StudentsLogs> createState() => _StudentsLogsState();
}

class _StudentsLogsState extends State<StudentsLogs> {
  String _selectedDate = DateTime.now().toIso8601String().split('T')[0]; // Default to current date (2025-09-18)

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.parse(_selectedDate);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildMobile(),
      desktop: _buildDesktop(),
    );
  }

  Widget _buildMobile() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: FirebaseService.getStudentLogsByDate(_selectedDate),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var logs = snapshot.data!;
          return SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Full Name')),
                DataColumn(label: Text('Year & Section')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('Emergency Contact')),
                DataColumn(label: Text('Morning In')),
                DataColumn(label: Text('Morning Out')),
                DataColumn(label: Text('Afternoon In')),
                DataColumn(label: Text('Afternoon Out')),
              ],
              rows: logs.map((log) {
                String formatTime(Timestamp? timestamp) {
                  if (timestamp == null) return 'N/A';
                  return TimeOfDay.fromDateTime(timestamp.toDate()).format(context);
                }
                return DataRow(cells: [
                  DataCell(Text(log['fullName'] ?? 'N/A')),
                  DataCell(Text(log['yearAndSection'] ?? 'N/A')),
                  DataCell(Text(log['address'] ?? 'N/A')),
                  DataCell(Text(log['emergencyContact'] ?? 'N/A')),
                  DataCell(Text(formatTime(log['morningIn']))),
                  DataCell(Text(formatTime(log['morningOut']))),
                  DataCell(Text(formatTime(log['afternoonIn']))),
                  DataCell(Text(formatTime(log['afternoonOut']))),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktop() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          ElevatedButton(
            onPressed: () => importExcelAndUploadToFirebase('student'),
            child: const Text("Import Excel"),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: FirebaseService.getStudentLogsByDate(_selectedDate),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var logs = snapshot.data!;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Full Name')),
                DataColumn(label: Text('Year & Section')),
                DataColumn(label: Text('Address')),
                DataColumn(label: Text('Emergency Contact')),
                DataColumn(label: Text('Morning In')),
                DataColumn(label: Text('Morning Out')),
                DataColumn(label: Text('Afternoon In')),
                DataColumn(label: Text('Afternoon Out')),
              ],
              rows: logs.map((log) {
                String formatTime(Timestamp? timestamp) {
                  if (timestamp == null) return 'N/A';
                  return TimeOfDay.fromDateTime(timestamp.toDate()).format(context);
                }
                return DataRow(cells: [
                  DataCell(Text(log['fullName'] ?? 'N/A')),
                  DataCell(Text(log['yearAndSection'] ?? 'N/A')),
                  DataCell(Text(log['address'] ?? 'N/A')),
                  DataCell(Text(log['emergencyContact'] ?? 'N/A')),
                  DataCell(Text(formatTime(log['morningIn']))),
                  DataCell(Text(formatTime(log['morningOut']))),
                  DataCell(Text(formatTime(log['afternoonIn']))),
                  DataCell(Text(formatTime(log['afternoonOut']))),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}