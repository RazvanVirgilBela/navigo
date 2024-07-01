// lib/auth/main_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_location/auth/auth_page.dart';
import 'package:my_location/screens/home_page.dart';
import 'package:my_location/services/firebase_services.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const AuthPage();
          }
        },
      ),
    );
  }
}
