import 'dart:developer';
import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import '../services/firebase_service.dart';
import 'result_page.dart';

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  String selectedAttendanceType = 'Morning IN';

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[50],
            child: DropdownButton<String>(
              value: selectedAttendanceType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Morning IN', child: Text('Morning IN')),
                DropdownMenuItem(value: 'Morning OUT', child: Text('Morning OUT')),
                DropdownMenuItem(value: 'Afternoon IN', child: Text('Afternoon IN')),
                DropdownMenuItem(value: 'Afternoon OUT', child: Text('Afternoon OUT')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedAttendanceType = newValue;
                  });
                }
              },
            ),
          ),
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                        'Scanned LRN: ${result!.code}',
                        style: const TextStyle(fontSize: 16),
                    )
                  else
                    const Text('Scan a QR code', style: TextStyle(fontSize: 18)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.toggleFlash();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getFlashStatus(),
                              builder: (context, snapshot) {
                                return Text('Flash: ${snapshot.data}');
                              },
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.flipCamera();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getCameraInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.data != null) {
                                  return Text(
                                      'Camera facing ${describeEnum(snapshot.data!)}');
                                } else {
                                  return const Text('loading');
                                }
                              },
                            )),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
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
      String attendanceType = selectedAttendanceType.toLowerCase().replaceAll(' ', '_'); // Define attendanceType
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
      _showPopupAndAutoDismiss(context, false, 'Error', lrn, 'N/A', selectedAttendanceType.toLowerCase().replaceAll(' ', '_'), false); // Fallback to original
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
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: ResultPage(
            isSuccess: isSuccess,
            name: name,
            lrn: lrn,
            section: section,
            attendanceType: attendanceType, // Ensure this matches the parameter
            isDone: isDone,
          ),
        ),
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
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No camera permission')),
      );
    }
  }
}