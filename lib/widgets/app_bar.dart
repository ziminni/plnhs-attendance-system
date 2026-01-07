import 'package:flutter/material.dart';
import 'dart:io';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showMenuButton;
  final bool isDesktop;
  final Color primaryBlue;
  final Color darkBlue;
  final Color accentBlue;

  const CustomAppBar({
    super.key,
    this.showMenuButton = false,
    this.isDesktop = false,
    required this.primaryBlue,
    required this.darkBlue,
    required this.accentBlue,
  });

  @override
  Size get preferredSize => Size.fromHeight(isDesktop ? 100 : 80);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _isOnline = false;
  late Future<void> _checkFuture;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    // Check internet connection every 2 seconds continuously
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        await _checkInternetConnection();
      }
      return mounted;
    });
  }

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 2), onTimeout: () => []);
      final isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.primaryBlue, widget.darkBlue, widget.accentBlue],
          stops: const [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        top: !widget.isDesktop,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isDesktop ? 24.0 : 16.0,
            vertical: widget.isDesktop ? 12.0 : 8.0,
          ),
          child: Row(
            children: [
              if (widget.showMenuButton)
                Builder(
                  builder: (context) => Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                padding: EdgeInsets.all(
                  widget.isDesktop ? 16 : 10,
                ), // Smaller padding for mobile
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(
                    widget.isDesktop ? 20 : 12,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.child_care,
                  color: Colors.white,
                  size: widget.isDesktop ? 36 : 28, // Smaller icon for mobile
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFE3F2FD)],
                      ).createShader(bounds),
                      child: Text(
                        "E.A.R.L.Y",
                        style: TextStyle(
                          fontSize: widget.isDesktop
                              ? 36
                              : 28, // Smaller font for mobile
                          fontWeight: FontWeight.w800,
                          letterSpacing: widget.isDesktop ? 3.0 : 2.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      widget.isDesktop
                          ? "Early Assessment & Recognition Learning Yard - Desktop Platform"
                          : "Early Assessment & Recognition",
                      style: TextStyle(
                        fontSize: widget.isDesktop
                            ? 16
                            : 12, // Smaller font for mobile
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isDesktop)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.desktop_windows,
                            color: Colors.white.withOpacity(0.8),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Desktop",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.account_circle,
                        color: Colors.white.withOpacity(0.9),
                        size: 24,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isOnline
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isOnline
                          ? Colors.green.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOnline ? Icons.wifi : Icons.wifi_off,
                        color: _isOnline
                            ? Colors.green.withOpacity(0.9)
                            : Colors.grey.withOpacity(0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOnline ? "Online" : "Offline",
                        style: TextStyle(
                          color: _isOnline
                              ? Colors.green.withOpacity(0.9)
                              : Colors.grey.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
