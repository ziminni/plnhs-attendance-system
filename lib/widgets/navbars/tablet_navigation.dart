import 'package:early_v1_0/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class TabletNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<Widget> pages;
  final Animation<double> fadeAnimation;
  final Color primaryBlue;
  final Color lightBlue;
  final Color darkBlue;
  final Color accentBlue;

  const TabletNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.pages,
    required this.fadeAnimation,
    required this.primaryBlue,
    required this.lightBlue,
    required this.darkBlue,
    required this.accentBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        primaryBlue: primaryBlue,
        darkBlue: darkBlue,
        accentBlue: accentBlue,
      ),
      body: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, lightBlue.withOpacity(0.05)],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onItemTapped,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.transparent,
              selectedIconTheme: IconThemeData(
                color: Colors.white,
                size: 28,
              ),
              unselectedIconTheme: IconThemeData(
                color: Colors.grey[600],
                size: 24,
              ),
              selectedLabelTextStyle: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
              indicatorColor: primaryBlue,
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text("Home"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.camera_alt_outlined),
                  selectedIcon: Icon(Icons.camera_alt),
                  label: Text("Scanner"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text("Settings"),
                ),
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            color: lightBlue.withOpacity(0.3),
          ),
          Expanded(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}