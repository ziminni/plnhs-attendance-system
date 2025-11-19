import 'package:early_v1_0/pages/home_page.dart';
import 'package:early_v1_0/pages/scanner_page.dart';
import 'package:early_v1_0/pages/settings_page.dart';
import 'package:early_v1_0/widgets/navbars/desktop_navigation.dart';
import 'package:early_v1_0/widgets/navbars/mobile_navigation.dart';
import 'package:early_v1_0/widgets/responsive_widget.dart';
import 'package:early_v1_0/widgets/navbars/tablet_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StaffResponsiveScaffold extends StatefulWidget {
  const StaffResponsiveScaffold({super.key});

  @override
  State<StaffResponsiveScaffold> createState() => _StaffResponsiveScaffoldState();
}

class _StaffResponsiveScaffoldState extends State<StaffResponsiveScaffold>
    with TickerProviderStateMixin<StaffResponsiveScaffold> {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _pages = [const HomePage(), const QRViewExample(), const SettingsPage()];

  // Blue theme colors
  final Color primaryBlue = const Color(0xFF1E88E5);
  final Color lightBlue = const Color(0xFF64B5F6);
  final Color darkBlue = const Color(0xFF0D47A1);
  final Color accentBlue = const Color(0xFF42A5F5);

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    // Set immersive mode for mobile and tablet after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Ensure widget is still mounted
      final screenWidth = MediaQuery.of(context).size.width;
      SystemChrome.setEnabledSystemUIMode(
        screenWidth < 1200 ? SystemUiMode.immersive : SystemUiMode.edgeToEdge,
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _animationController.reset();
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWidget(
      mobile: MobileNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        pages: _pages,
        fadeAnimation: _fadeAnimation,
        primaryBlue: primaryBlue,
        lightBlue: lightBlue,
        darkBlue: darkBlue,
        accentBlue: accentBlue,
      ),
      tablet: TabletNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        pages: _pages,
        fadeAnimation: _fadeAnimation,
        primaryBlue: primaryBlue,
        lightBlue: lightBlue,
        darkBlue: darkBlue,
        accentBlue: accentBlue,
      ),
      desktop: DesktopNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        pages: _pages,
        fadeAnimation: _fadeAnimation,
        primaryBlue: primaryBlue,
        lightBlue: lightBlue,
        darkBlue: darkBlue,
        accentBlue: accentBlue,
      ),
    );
  }
}