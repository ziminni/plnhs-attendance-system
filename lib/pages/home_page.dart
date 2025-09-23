import 'package:early_v1_0/widgets/responsive_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 Required for sign out

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWidget(
        mobile: _buildMobile(context),
        tablet: _buildTablet(),
        desktop: _buildDesktop(),
      ),
    );
  }
}

Widget _buildMobile(BuildContext context) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Mobile Platform"),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut(); // 👈 Sign out from Firebase
            Navigator.pushReplacementNamed(context, '/login'); // 👈 Go back to login
          },
          child: const Text("Sign Out"),
        ),
      ],
    ),
  );
}

Widget _buildTablet() {
  return const Center(
    child: Text("Tablet Platform"),
  );
}

Widget _buildDesktop() {
  return const Center(
    child: Text("Desktop Platform"),
  );
}
