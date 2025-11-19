import 'package:early_v1_0/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class MobileNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<Widget> pages;
  final Animation<double> fadeAnimation;
  final Color primaryBlue;
  final Color lightBlue;
  final Color darkBlue;
  final Color accentBlue;

  const MobileNavigation({
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
        showMenuButton: false, // Explicitly disable menu button for mobile
      ),
      body: FadeTransition(
        opacity: fadeAnimation,
        child: pages[selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lightBlue.withOpacity(0.1), Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: primaryBlue,
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 11,
            ),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                label: "Home",
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
              ),
              BottomNavigationBarItem(
                label: "Scanner",
                icon: Icon(Icons.camera_alt_outlined),
                activeIcon: Icon(Icons.camera_alt),
              ),
              BottomNavigationBarItem(
                label: "Settings",
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
