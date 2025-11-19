import 'package:early_v1_0/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class DesktopNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final List<Widget> pages;
  final Animation<double> fadeAnimation;
  final Color primaryBlue;
  final Color lightBlue;
  final Color darkBlue;
  final Color accentBlue;

  const DesktopNavigation({
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
        showMenuButton: true,
        isDesktop: true,
        primaryBlue: primaryBlue,
        darkBlue: darkBlue,
        accentBlue: accentBlue,
      ),
      drawer: SizedBox(
        width: 280,
        child: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, lightBlue.withOpacity(0.05)],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryBlue, darkBlue],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Navigation Menu",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDrawerItem(context, Icons.home_outlined, Icons.home, "Home", 0),
                _buildDrawerItem(context, Icons.camera_alt_outlined, Icons.camera_alt, "Scanner", 1),
                _buildDrawerItem(context, Icons.settings_outlined, Icons.settings, "Settings", 2),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: fadeAnimation,
        child: pages[selectedIndex],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, // Added BuildContext parameter
      IconData icon,
      IconData selectedIcon,
      String title,
      int index,
  ) {
    bool isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isSelected ? selectedIcon : icon,
            key: ValueKey(isSelected),
            color: isSelected ? Colors.white : Colors.grey[600],
            size: isSelected ? 26 : 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        selected: isSelected,
        selectedTileColor: primaryBlue.withOpacity(0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () {
          Navigator.of(context).pop(); // Use passed context
          onItemTapped(index);
        },
      ),
    );
  }
}
