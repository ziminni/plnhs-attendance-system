import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Web Platform"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance
                  .signOut(); // 👈 Sign out from Firebase
              Navigator.pushReplacementNamed(
                context,
                '/login',
              ); // 👈 Go back to login
            },
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );
  }
}
