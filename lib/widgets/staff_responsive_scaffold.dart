import 'package:early_v1_0/pages/home_page.dart';
import 'package:early_v1_0/pages/scanner_page.dart';
import 'package:early_v1_0/pages/settings_page.dart';
import 'package:early_v1_0/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';

class StaffResponsiveScaffold extends StatefulWidget {
  const StaffResponsiveScaffold({super.key});

  @override
  State<StaffResponsiveScaffold> createState() =>
      _StaffResponsiveScaffoldState();
}

class _StaffResponsiveScaffoldState extends State<StaffResponsiveScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [HomePage(), QRViewExample(), SettingsPage()];

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
    return Scaffold(
      appBar: AppBar(title: Text("E.A.R.L.Y")),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(label: "Home", icon: Icon(Icons.home)),
          BottomNavigationBarItem(
            label: "Scanner",
            icon: Icon(Icons.camera_alt_outlined),
          ),
          BottomNavigationBarItem(
            label: "Settings",
            icon: Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildTablet() {
    return Scaffold(
      appBar: AppBar(
        title: Text("This is Tablet"),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home), label: Text("Home")),
              NavigationRailDestination(icon: Icon(Icons.camera_alt_outlined), label: Text("Scanner")),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text("Settings")),
          ]),
          VerticalDivider(width: 1,),
          Expanded(child: _pages[_selectedIndex])
        ],
      )
    );
  }

  Widget _buildDesktop() {
    return Scaffold(
      appBar: AppBar(title: Text("Responsive App")),
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
              leading: Icon(Icons.camera_alt_outlined),
              title: Text("Scanner"),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTappedAndClose(1),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTappedAndClose(1),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  void _onItemTappedAndClose(int index) {
    Navigator.of(context).pop(); // close drawer
    _onItemTapped(index);
  }
}
