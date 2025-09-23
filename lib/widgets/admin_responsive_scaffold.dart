import 'package:early_v1_0/pages/admin/admin_dashboard.dart';
import 'package:early_v1_0/pages/admin/archive_logs.dart';
import 'package:early_v1_0/pages/admin/students_logs.dart';
import 'package:early_v1_0/pages/admin/teachers_logs.dart';
import 'package:early_v1_0/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';

class AdminResponsiveScaffold extends StatefulWidget {
  const AdminResponsiveScaffold({super.key});

  @override
  State<AdminResponsiveScaffold> createState() =>
      _AdminResponsiveScaffoldState();
}

class _AdminResponsiveScaffoldState extends State<AdminResponsiveScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AdminDashboard(),
    StudentsLogs(),
    TeachersLogs(),
    ArchiveLogs(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: _buildMobile(),
      tablet: _buildTablet(),
      desktop: _buildDesktop(),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMobile() {
    return Scaffold();
  }

  Widget _buildTablet() {
    return Scaffold();
  }

  Widget _buildDesktop() {
    return Scaffold(
      appBar: AppBar(
        title: Text("Website Early!")
        ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text("Menu")),
            ListTile(
              leading: Icon(Icons.home),
              title: Text("Home"),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTappedAndClose(0),
            ),
            ListTile(
              leading: Icon(Icons.class_),
              title: Text("Students Logs"),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTappedAndClose(1),
            ),
            ListTile(
              leading: Icon(Icons.developer_board),
              title: Text("Teachers Logs"),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTappedAndClose(2),
            ),
            ListTile(
              leading: Icon(Icons.archive),
              title: Text("Archive"),
              selected: _selectedIndex == 3,
              onTap: () => _onItemTappedAndClose(3),
            ),
            // ListTile(
            //   leading: Icon(Icons.home),
            //   title: Text("Home"),
            //   selected: _selectedIndex == 4,
            //   onTap: () => _onItemTappedAndClose(4),
            // ),
            // ListTile(
            //   leading: Icon(Icons.home),
            //   title: Text("Home"),
            //   selected: _selectedIndex == 5,
            //   onTap: () => _onItemTappedAndClose(5),
            // ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  void _onItemTappedAndClose(int index) {
    Navigator.of(context).pop(); // closes the drawer
    _onItemTapped(index);
  }
}
