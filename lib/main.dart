import 'package:early_v1_0/login.dart';
import 'package:early_v1_0/services/firebase_service.dart';
import 'package:early_v1_0/widgets/admin_responsive_scaffold.dart';
import 'package:early_v1_0/widgets/staff_responsive_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

void main() async {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive); //Fullscreen
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDOw6pfCjFzsbBrrJ64vIW0SS0dBMOBvs0",
        authDomain: "early-qrscanner.firebaseapp.com",
        projectId: "early-qrscanner",
        storageBucket: "early-qrscanner.firebasestorage.app",
        messagingSenderId: "814044585268",
        appId: "1:814044585268:web:690b9e4dfb75664f02d961",
        measurementId: "G-T3M9RZ8FN1",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "E.A.R.L.Y",
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(), //AuthChecker
        '/login': (context) => const LoginPage(), //Login Form
        '/staff': (context) => const StaffResponsiveScaffold(), //Staff Homepage
        '/admin': (context) => const AdminResponsiveScaffold(), //Admin Homepage
      },
    );
  }
}

// Checks current session
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print("🔥 Logged-in UID: ${user?.uid}");

    if (user == null) {
      return const LoginPage(); // Not logged in!
    }

    return FutureBuilder(
      future: FirebaseService().getRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final role = snapshot.data;

        if (role == null) {
          return const Center(child: Scaffold(body: Text("User not found in the database!")));
        }

        if (role == 'admin') {
          return const AdminResponsiveScaffold();
        } else if (role == 'staff') {
          return const StaffResponsiveScaffold();
        }else {
          print("❌ Unknown role: $role");
          return const Scaffold(
              body: Center(child: Text("Unknown role or not authorized")));
        }
      },
    );
  }
}
