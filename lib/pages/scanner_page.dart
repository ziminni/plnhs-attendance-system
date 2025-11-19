import 'dart:developer';
import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../services/firebase_service.dart';
import 'result_page.dart';

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample>
    with TickerProviderStateMixin {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String selectedAttendanceType = 'Morning IN';
  bool _isFlashOn = false;
  bool _isScanning = true;
  bool _controlsVisible = true;
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<AttendanceType> attendanceTypes = [
    AttendanceType('Morning IN', Icons.wb_sunny_outlined, Colors.orange),
    AttendanceType('Morning OUT', Icons.wb_sunny, Colors.orange.shade700),
    AttendanceType('Afternoon IN', Icons.brightness_3_outlined, Colors.blue),
    AttendanceType('Afternoon OUT', Icons.brightness_3, Colors.blue.shade700),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    
    if (_controlsVisible) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onDoubleTap: _toggleControls,
        child: Stack(
          children: [
            // QR Scanner View - Full screen
            Positioned.fill(
              child: _buildQrView(context),
            ),
            
            // Top Controls - Animated
            if (_controlsVisible)
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: SafeArea(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _buildAttendanceSelector(),
                      ),
                    ),
                  );
                },
              ),

            // Scanning Indicator - Always visible in center
            Center(
              child: Container(
                width: 230, // Fixed size
                height: 230, // Fixed size
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isScanning ? Colors.green : Colors.red,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    ..._buildCornerDecorations(),

                    // Center icon when not scanning
                    if (!_isScanning)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Bottom Controls - Animated
            if (_controlsVisible)
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: SafeArea(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, -10),
                              ),
                            ],
                          ),
                          child: _buildBottomControls(),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Attendance Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButton<String>(
              value: selectedAttendanceType,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: attendanceTypes.map((type) {
                return DropdownMenuItem(
                  value: type.name,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: type.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          type.icon,
                          color: type.color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        type.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedAttendanceType = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (result != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scanned LRN',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          result!.code ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Point camera at QR code to scan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  onPressed: () async {
                    await controller?.toggleFlash();
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                    });
                  },
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  label: _isFlashOn ? 'Flash On' : 'Flash Off',
                  color: _isFlashOn ? Colors.amber : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildControlButton(
                  onPressed: () async {
                    await controller?.flipCamera();
                  },
                  icon: Icons.flip_camera_ios,
                  label: 'Flip Camera',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCornerDecorations() {
    return [
      // Top-left corner
      Positioned(
        top: 10,
        left: 10,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _isScanning ? Colors.green : Colors.red, width: 3),
              left: BorderSide(color: _isScanning ? Colors.green : Colors.red, width: 3),
            ),
          ),
        ),
      ),
      // Top-right corner
      Positioned(
        top: 10,
        right: 10,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: _isScanning ? Colors.green : Colors.red, width: 3),
              right: BorderSide(color: _isScanning ? Colors.green : Colors.red, width: 3),
            ),
          ),
        ),
      ),
      // Bottom-left corner
      Positioned(
        bottom: 10,
        left: 10,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _isScanning ? Colors.green : Colors.red, width: 3),
              left: BorderSide(color: _isScanning ? Colors.green : Colors.red, width: 3),
            ),
          ),
        ),
      ),
      // Bottom-right corner
      Positioned(
        bottom: 10,
        right: 10,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _isScanning ? Colors.green : Colors.red, width: 3),
              right: BorderSide(color: _isScanning ? Colors.green : Colors.red, width: 3),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildQrView(BuildContext context) {
    const scanArea = 320.0; // Fixed scan area size
    
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.transparent,
        borderRadius: 20,
        borderLength: 0,
        borderWidth: 0,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        _isScanning = false;
      });
      _handleScan(scanData);
    });
  }

  Future<void> _handleScan(Barcode scanData) async {
    if (scanData.code == null) {
      log('No code detected');
      return;
    }

    String rawLrn = scanData.code!;
    String lrn = rawLrn.trim().replaceAll(RegExp(r'\s+'), '');
    log('Raw Scanned LRN: $rawLrn');
    log('Cleaned Scanned LRN: $lrn');
    await controller?.pauseCamera();

    try {
      String attendanceType = selectedAttendanceType.toLowerCase().replaceAll(' ', '_');
      log('Processing attendance type: $attendanceType');
      Map<String, dynamic>? userData = await _fetchUserData(lrn);
      if (userData == null) {
        log('User not found for LRN: $lrn');
        _showPopupAndAutoDismiss(context, false, 'Unknown User', lrn, 'N/A', attendanceType, false);
        return;
      }

      String label = userData['label']?.toString().toLowerCase() ?? '';
      bool isDone = false;

      if (label == 'student') {
        DocumentSnapshot logDoc = await FirebaseFirestore.instance
            .collection('student_logs')
            .doc(lrn)
            .get();
        if (logDoc.exists) {
          var data = logDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            switch (attendanceType) {
              case 'morning_in':
                isDone = data['morningIn'] != null;
                break;
              case 'morning_out':
                isDone = data['morningOut'] != null;
                break;
              case 'afternoon_in':
                isDone = data['afternoonIn'] != null;
                break;
              case 'afternoon_out':
                isDone = data['afternoonOut'] != null;
                break;
            }
          }
        }

        if (!isDone) {
          await FirebaseService.logAttendance(lrn, attendanceType);
          log('Student attendance logged for LRN: $lrn, Type: $attendanceType');
          String fullName = '${userData['firstname'] ?? ''} ${userData['middlename'] ?? ''} ${userData['lastname'] ?? ''}'.trim();
          String section = userData['grade_and_section'] ?? 'Unknown';
          _showPopupAndAutoDismiss(context, true, fullName, lrn, section, attendanceType, false);
        } else {
          _showPopupAndAutoDismiss(context, true, 'Already Done', lrn, 'N/A', attendanceType, true);
        }
      } else if (label == 'teacher') {
        DocumentSnapshot logDoc = await FirebaseFirestore.instance
            .collection('teacher_logs')
            .doc(lrn)
            .get();
        if (logDoc.exists) {
          var data = logDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            switch (attendanceType) {
              case 'morning_in':
                isDone = data['morningIn'] != null;
                break;
              case 'morning_out':
                isDone = data['morningOut'] != null;
                break;
              case 'afternoon_in':
                isDone = data['afternoonIn'] != null;
                break;
              case 'afternoon_out':
                isDone = data['afternoonOut'] != null;
                break;
            }
          }
        }

        if (!isDone) {
          await FirebaseService.logTeacherAttendance(lrn, attendanceType);
          log('Teacher attendance logged for LRN: $lrn, Type: $attendanceType');
          String fullName = userData['fullname'] ?? 'Unknown';
          _showPopupAndAutoDismiss(context, true, fullName, lrn, 'N/A', attendanceType, false);
        } else {
          _showPopupAndAutoDismiss(context, true, 'Already Done', lrn, 'N/A', attendanceType, true);
        }
      } else {
        _showPopupAndAutoDismiss(context, false, 'Unknown User Type', lrn, 'N/A', attendanceType, false);
      }
    } catch (e) {
      log('Error handling scan: $e');
      _showPopupAndAutoDismiss(context, false, 'Error', lrn, 'N/A', selectedAttendanceType.toLowerCase().replaceAll(' ', '_'), false);
    } finally {
      _resumeAndReset();
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData(String lrn) async {
    // Try students collection first
    Map<String, dynamic>? data = await FirebaseService.getStudentByLrn(lrn);
    if (data != null && data['label'] == 'student') {
      log('Found student data for LRN: $lrn');
      return data;
    }
    // If not found or not a student, try teachers collection
    DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(lrn)
        .get();
    if (teacherDoc.exists) {
      log('Found teacher data for LRN: $lrn');
      return teacherDoc.data() as Map<String, dynamic>?;
    }
    log('No data found for LRN: $lrn');
    return null;
  }

  void _showPopupAndAutoDismiss(BuildContext context, bool isSuccess, String name, String lrn, String section, String attendanceType, bool isDone) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          body: ResultPage(
            isSuccess: isSuccess,
            name: name,
            lrn: lrn,
            section: section,
            attendanceType: attendanceType,
            isDone: isDone,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) {
      _resumeAndReset();
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _resumeAndReset() {
    controller?.resumeCamera();
    setState(() {
      result = null;
      _isScanning = true;
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Camera permission required'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

class AttendanceType {
  final String name;
  final IconData icon;
  final Color color;

  AttendanceType(this.name, this.icon, this.color);
}