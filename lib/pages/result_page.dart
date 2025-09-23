import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final bool isSuccess;
  final String name;
  final String lrn;
  final String section;
  final String attendanceType;
  final bool isDone; // Parameter for "done" status

  const ResultPage({
    super.key,
    required this.isSuccess,
    required this.name,
    required this.lrn,
    required this.section,
    required this.attendanceType,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDone
                ? [Color(0xFFFCE4D6), Color(0xFFFFE0B2)] // Light yellow gradient for done
                : (isSuccess
                    ? [Color(0xFFD9EAD3), Color(0xFFC6E0B4)] // Light green gradient for success
                    : [Color(0xFFF4CCCC), Color(0xFFF2B2B2)]), // Light red gradient for failure
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8.0,
            margin: EdgeInsets.all(20.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: isDone
                        ? Color(0xFFFFD700) // Bright yellow for done
                        : (isSuccess
                            ? Color(0xFF6AA84F) // Rich green for success
                            : Color(0xFFCC0000)), // Deep red for failure
                    child: Icon(
                      isDone
                          ? Icons.check_circle // Check circle for done
                          : (isSuccess ? Icons.check : Icons.close),
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'LRN: $lrn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black54,
                    ),
                  ),
                  if (section != 'N/A') ...[
                    SizedBox(height: 10),
                    Text(
                      section,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                  SizedBox(height: 20),
                  Text(
                    isDone
                        ? 'Already Done - $attendanceType!'
                        : (isSuccess
                            ? 'Logged Successfully - $attendanceType!'
                            : 'Login Failed!'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? Colors.orange[700]
                          : (isSuccess
                              ? Colors.green[700]
                              : Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}