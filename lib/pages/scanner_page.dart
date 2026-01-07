import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../services/firebase_service.dart';
import '../services/local_db_service.dart';
import '../models/models.dart';
import 'result_page.dart';

class AttendanceTypeItem {
  final String name;
  final IconData icon;
  final Color color;
  final AttendanceType type;
  AttendanceTypeItem(this.name, this.icon, this.color, this.type);
}

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

  final List<AttendanceTypeItem> attendanceTypes = [
    AttendanceTypeItem(
      'Morning IN',
      Icons.wb_sunny_outlined,
      Colors.orange,
      AttendanceType.morningIn,
    ),
    AttendanceTypeItem(
      'Morning OUT',
      Icons.wb_sunny,
      Colors.orange.shade700,
      AttendanceType.morningOut,
    ),
    AttendanceTypeItem(
      'Afternoon IN',
      Icons.brightness_3_outlined,
      Colors.blue,
      AttendanceType.afternoonIn,
    ),
    AttendanceTypeItem(
      'Afternoon OUT',
      Icons.brightness_3,
      Colors.blue.shade700,
      AttendanceType.afternoonOut,
    ),
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
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    controller?.dispose();
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

  String _getSqliteField(AttendanceType type) {
    switch (type) {
      case AttendanceType.morningIn:
        return 'time_in_morning';
      case AttendanceType.morningOut:
        return 'time_out_morning';
      case AttendanceType.afternoonIn:
        return 'time_in_afternoon';
      case AttendanceType.afternoonOut:
        return 'time_out_afternoon';
      default:
        return '';
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
            Positioned.fill(child: _buildQrView(context)),
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
            Center(
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isScanning ? Colors.green : Colors.red,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    ..._buildCornerDecorations(),
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
                child: const Icon(Icons.schedule, color: Colors.blue, size: 20),
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
                        child: Icon(type.icon, color: type.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        type.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
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
                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
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
      Positioned(
        top: 10,
        left: 10,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: _isScanning ? Colors.green : Colors.red,
                width: 3,
              ),
              left: BorderSide(
                color: _isScanning ? Colors.green : Colors.red,
                width: 3,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 10,
        right: 10,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: _isScanning ? Colors.green : Colors.red,
                width: 3,
              ),
              right: BorderSide(
                color: _isScanning ? Colors.green : Colors.red,
                width: 3,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 10,
        left: 10,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _isScanning ? Colors.green : Colors.red,
                width: 3,
              ),
              left: BorderSide(
                color: _isScanning ? Colors.green : Colors.red,
                width: 3,
              ),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _isScanning ? Colors.green : Colors.red,
                width: 3,
              ),
              right: BorderSide(
                color: _isScanning ? Colors.green : Colors.red,
                width: 3,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildQrView(BuildContext context) {
    const scanArea = 320.0;
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
    log('======== SCAN DEBUG ========');
    log('Raw Scanned LRN: "$rawLrn"');
    log('Cleaned Scanned LRN: "$lrn"');
    log('LRN length: ${lrn.length}');
    log('============================');
    await controller?.pauseCamera();
    try {
      final attendanceType = AttendanceType.fromString(selectedAttendanceType);
      log('Processing attendance type: ${attendanceType.displayName}');
      final userData = await _fetchUserData(lrn);
      if (userData == null) {
        log('❌ User not found for LRN: $lrn');
        if (mounted) {
          _showPopupAndAutoDismiss(
            context,
            false,
            'Unknown User',
            lrn,
            'N/A',
            attendanceType.displayName,
            false,
          );
        }
        return;
      }
      log(
        '✅ User found: ${userData['fullname'] ?? userData['full_name'] ?? 'Unknown'}',
      );
      final dbService = LocalDbService();
      final staffList = await dbService.getAllStaff();
      // Direct comparison - both normalized to lowercase during sync
      final dbUserList = staffList.where((s) => s['id_number'] == lrn).toList();
      final dbUser = dbUserList.isEmpty ? null : dbUserList.first;
      log('👤 Found DB user: $dbUser');
      log('👤 Staff list size: ${staffList.length}');
      log('👤 Searching for LRN: $lrn');
      log('👤 DB User fullname field: ${dbUser?['fullname']}');
      if (dbUser == null) {
        log('User not found locally for LRN: $lrn');
        if (mounted) {
          _showPopupAndAutoDismiss(
            context,
            false,
            'Unknown User',
            lrn,
            'N/A',
            attendanceType.displayName,
            false,
          );
        }
        return;
      }
      final attendanceRecords = await dbService.getAttendanceByStaff(
        dbUser['id'],
      );
      final today = DateTime.now().toIso8601String().substring(0, 10);
      log('📅 Today date: $today');
      log('📝 All records for staff: $attendanceRecords');
      final todayRecordList = attendanceRecords
          .where((a) => (a['date'] ?? '').toString().startsWith(today))
          .toList();
      log('📝 Today\'s records: $todayRecordList');
      final todayRecord = todayRecordList.isEmpty
          ? null
          : todayRecordList.first;
      String sqliteField = _getSqliteField(attendanceType);
      log(
        '🔍 Checking field "$sqliteField" in record: ${todayRecord?[sqliteField]}',
      );
      bool isDone = (todayRecord != null && todayRecord[sqliteField] != null);

      if (!isDone) {
        try {
          if (todayRecord == null) {
            // Insert new record
            Map<String, dynamic> attendance = {
              'staff_id': dbUser['id'],
              'date': today,
              sqliteField: DateTime.now().toIso8601String(),
            };
            log('📝 Inserting new attendance record: $attendance');
            await dbService.insertAttendance(attendance);
          } else {
            // Update existing record - only update the specific field
            Map<String, dynamic> updateData = {
              sqliteField: DateTime.now().toIso8601String(),
            };
            log(
              '📝 Updating existing attendance record (ID: ${todayRecord['id']}) with: $updateData',
            );
            await dbService.updateAttendance(todayRecord['id'], updateData);
          }
          log(
            'Attendance logged locally for LRN: $lrn, Type: ${attendanceType.displayName}',
          );
          log('👤 DB User full record: $dbUser');
          String fullName = dbUser['fullname'] ?? 'Unknown';
          String phone = dbUser['phone_number'] ?? 'N/A';
          log('📝 Using fullName: "$fullName" and phone: "$phone"');
          if (mounted) {
            _showPopupAndAutoDismiss(
              context,
              true,
              fullName,
              lrn,
              phone,
              attendanceType.displayName,
              false,
            );
          }
        } catch (e, stackTrace) {
          log('❌ Error saving attendance: $e');
          log('❌ Stack trace: $stackTrace');
          log('❌ Today record ID: ${todayRecord?['id']}');
          log('❌ Today record data: $todayRecord');
          log('❌ Update field: $sqliteField');
          log('❌ DB User ID: ${dbUser['id']}');
          if (mounted) {
            _showPopupAndAutoDismiss(
              context,
              false,
              'Error Saving',
              lrn,
              'DB: $e',
              attendanceType.displayName,
              false,
            );
          }
        }
      } else {
        if (mounted) {
          _showPopupAndAutoDismiss(
            context,
            true,
            'Already Done',
            lrn,
            'N/A',
            attendanceType.displayName,
            true,
          );
        }
      }
    } catch (e) {
      log('Error handling scan: $e');
      if (mounted) {
        _showPopupAndAutoDismiss(
          context,
          false,
          'Error',
          scanData.code ?? '',
          'N/A',
          selectedAttendanceType,
          false,
        );
      }
    } finally {
      _resumeAndReset();
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData(String lrn) async {
    log('🔍 _fetchUserData called with LRN: "$lrn"');

    // Normalize the LRN (trim and lowercase for comparison)
    final normalizedLrn = lrn.trim().toLowerCase();

    // First, try to get from local database (works offline)
    final dbService = LocalDbService();
    final staffList = await dbService.getAllStaff();
    log('📱 Local DB staff count: ${staffList.length}');
    if (staffList.isNotEmpty) {
      log(
        '📱 Sample local staff IDs: ${staffList.take(3).map((s) => '${s['id_number']}').toList()}',
      );
    }

    // Try exact match first, then case-insensitive
    var localStaff = staffList
        .where(
          (s) =>
              (s['id_number']?.toString().trim().toLowerCase() ?? '') ==
              normalizedLrn,
        )
        .toList();

    if (localStaff.isNotEmpty) {
      log(
        '✅ Found staff in local DB for LRN: $lrn (matched: ${localStaff.first['id_number']})',
      );
      return localStaff.first;
    }

    log('⚠️ No local match found. Checking Firebase...');

    // If not found locally, try Firebase (requires internet)
    try {
      log('🌐 Querying Firebase for student and teacher...');
      final results = await Future.wait([
        FirebaseService.getStudentByLrn(lrn),
        FirebaseService.getTeacherByLrn(lrn),
      ]).timeout(const Duration(seconds: 5));

      final student = results[0] as Student?;
      final teacher = results[1] as Teacher?;

      log(
        '🌐 Firebase student result: ${student != null ? 'FOUND' : 'NOT FOUND'}',
      );
      log(
        '🌐 Firebase teacher result: ${teacher != null ? 'FOUND' : 'NOT FOUND'}',
      );

      if (student != null) {
        log('✅ Found student for LRN: $lrn');
        // Insert student into local DB for future offline use
        final staffData = {
          'id_number': lrn.toLowerCase(),
          'fullname': student.fullName,
          'phone_number': student.guardianContact ?? 'N/A',
        };
        try {
          final dbService = LocalDbService();
          await dbService.insertOrUpdateStaff(staffData);
          log('💾 Cached student to local DB');
        } catch (e) {
          log('⚠️ Failed to cache student: $e');
        }
        final data = student.toMap();
        data['label'] = 'student';
        data['fullname'] = student.fullName;
        data['id_number'] = lrn.toLowerCase();
        return data;
      }
      if (teacher != null) {
        log('✅ Found teacher for LRN: $lrn');
        // Insert teacher into local DB for future offline use
        final staffData = {
          'id_number': lrn.toLowerCase(),
          'fullname': teacher.fullname,
          'phone_number': teacher.emergencyContact ?? 'N/A',
        };
        try {
          final dbService = LocalDbService();
          await dbService.insertOrUpdateStaff(staffData);
          log('💾 Cached teacher to local DB');
        } catch (e) {
          log('⚠️ Failed to cache teacher: $e');
        }
        final data = teacher.toMap();
        data['label'] = 'teacher';
        data['fullname'] = teacher.fullname;
        data['id_number'] = lrn.toLowerCase();
        return data;
      }
    } catch (e) {
      log('❌ Firebase fetch failed (offline?): $e');
    }

    log('❌ No data found for LRN: $lrn');
    return null;
  }

  void _showPopupAndAutoDismiss(
    BuildContext context,
    bool isSuccess,
    String name,
    String lrn,
    String section,
    String attendanceType,
    bool isDone,
  ) {
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
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
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
      if (mounted && Navigator.canPop(context)) {
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

  Future<void> _syncStaffData() async {
    log('🔄 Starting staff data sync from Firebase...');

    // Check internet connection
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('No internet');
      }
    } on SocketException catch (_) {
      log('❌ No internet connection');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No internet connection available'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syncing staff & student data...'),
          duration: Duration(seconds: 2),
        ),
      );

      final dbService = LocalDbService();
      int synced = 0;

      // Fetch all teachers from Firebase
      try {
        log('📥 Fetching teachers...');
        final teachersSnapshot = await FirebaseFirestore.instance
            .collection('teachers')
            .get();
        log('📥 Found ${teachersSnapshot.docs.length} teachers in Firebase');

        for (var doc in teachersSnapshot.docs) {
          try {
            final teacherData = doc.data();
            log('📥 Teacher raw data: $teacherData');
            final lrn = (teacherData['lrn'] ?? doc.id)
                .toString()
                .trim()
                .toLowerCase();

            final fullName =
                teacherData['fullName'] ??
                teacherData['full_name'] ??
                teacherData['name'] ??
                teacherData['fullname'] ??
                'Unknown';
            log(
              '📥 Extracted fullName: "$fullName" from keys: ${teacherData.keys}',
            );

            final staffData = {
              'id_number': lrn,
              'fullname': fullName,
              'phone_number':
                  teacherData['contactNumber'] ??
                  teacherData['contact_number'] ??
                  'N/A',
            };

            await dbService.insertOrUpdateStaff(staffData);
            synced++;
            log('✅ Synced teacher: $lrn - $fullName');
          } catch (e, stackTrace) {
            log('⚠️ Failed to sync teacher: $e\n$stackTrace');
          }
        }
      } catch (e, stackTrace) {
        log('❌ Error fetching teachers: $e\n$stackTrace');
      }

      // Fetch all students from Firebase
      try {
        log('📥 Fetching students...');
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .get();
        log('📥 Found ${studentsSnapshot.docs.length} students in Firebase');

        for (var doc in studentsSnapshot.docs) {
          try {
            final studentData = doc.data();
            log('📥 Student raw data: $studentData');
            final lrn = (studentData['lrn'] ?? doc.id)
                .toString()
                .trim()
                .toLowerCase();

            final fullName =
                studentData['fullName'] ??
                studentData['full_name'] ??
                studentData['name'] ??
                studentData['fullname'] ??
                'Unknown';
            log(
              '📥 Extracted fullName: "$fullName" from keys: ${studentData.keys}',
            );

            final staffData = {
              'id_number': lrn,
              'fullname': fullName,
              'phone_number':
                  studentData['contactNumber'] ??
                  studentData['contact_number'] ??
                  'N/A',
            };

            await dbService.insertOrUpdateStaff(staffData);
            synced++;
            log('✅ Synced student: $lrn - $fullName');
          } catch (e, stackTrace) {
            log('⚠️ Failed to sync student: $e\n$stackTrace');
          }
        }
      } catch (e, stackTrace) {
        log('❌ Error fetching students: $e\n$stackTrace');
      }

      log('✅ Sync completed! $synced total records synced');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Synced $synced staff & students'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      log('❌ Sync failed: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sync failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _syncAttendanceToFirebase() async {
    log('🔄 Starting attendance upload to Firebase...');

    // Check internet connection
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw const SocketException('No internet');
      }
    } on SocketException catch (_) {
      log('❌ No internet connection');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ No internet connection available'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading attendance records...'),
          duration: Duration(seconds: 2),
        ),
      );

      final dbService = LocalDbService();
      int uploaded = 0;

      // Get all staff from local DB
      final staffList = await dbService.getAllStaff();
      log('📤 Found ${staffList.length} staff records to sync');

      for (var staff in staffList) {
        try {
          final staffId = staff['id'];
          final lrn = staff['id_number'];
          final fullName = staff['fullname'];

          // Get all attendance records for this staff
          final attendanceRecords = await dbService.getAttendanceByStaff(
            staffId,
          );
          log(
            '📤 Staff $lrn has ${attendanceRecords.length} attendance records',
          );

          // Check if this person is a teacher or student in Firebase
          final isTeacher = await FirebaseService.getTeacherByLrn(lrn) != null;
          final collectionName = isTeacher ? 'teacher_logs' : 'student_logs';
          log(
            '📤 $lrn is a ${isTeacher ? 'TEACHER' : 'STUDENT'} -> uploading to $collectionName',
          );

          for (var record in attendanceRecords) {
            try {
              // Use LRN as document ID (will merge with existing records)
              final docId = lrn;
              log('📤 Uploading to collection: $collectionName, docId: $docId');

              // Prepare attendance data for Firebase
              final attendanceData = {
                'fullName': fullName,
                'lrn': lrn,
                'date': record['date'],
                'morningIn': record['time_in_morning'],
                'morningOut': record['time_out_morning'],
                'afternoonIn': record['time_in_afternoon'],
                'afternoonOut': record['time_out_afternoon'],
              };
              log('📤 Attendance data: $attendanceData');

              // Upload to Firebase - merge with existing data
              await FirebaseFirestore.instance
                  .collection(collectionName)
                  .doc(docId)
                  .set(attendanceData, SetOptions(merge: true));

              uploaded++;
              log('✅ Uploaded to $collectionName/$docId');
            } catch (e, stackTrace) {
              log('⚠️ Failed to upload attendance record: $e\n$stackTrace');
            }
          }
        } catch (e, stackTrace) {
          log('⚠️ Failed to sync attendance for staff: $e\n$stackTrace');
        }
      }

      log('✅ Upload completed! $uploaded attendance records uploaded');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Uploaded $uploaded attendance records'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      log('❌ Upload failed: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Upload failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
