import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_location/models/user_model.dart';
import 'package:my_location/services/firebase_services.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterPage({
    super.key,
    required this.showLoginPage,
  });

  @override
  State<RegisterPage> createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
   final FirebaseService _firebaseService = FirebaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (passwordConfirmed()) {
      try {
        User? user = await _firebaseService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (user != null) {
          UserModel userModel = UserModel(
            uid: user.uid,
            email: user.email!,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            age: int.parse(_ageController.text.trim()),
          );
          await _firebaseService.addUserData(user.uid, userModel.toMap());
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
    }
  }

  bool passwordConfirmed() {
    return _passwordController.text.trim() == _confirmPasswordController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 400,
                height: 170,
                child: Stack(
                  children: [
                    Positioned(
                      left: -40,
                      top: -110,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: ShapeDecoration(
                          color: Colors.green.shade200,
                          shape: const OvalBorder(),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -110,
                      top: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: ShapeDecoration(
                          color: Colors.green.shade100,
                          shape: const OvalBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // App Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Navi',
                    style: GoogleFonts.inter(
                      color: Colors.teal.shade800,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'GO',
                    style: GoogleFonts.inter(
                      color: Colors.green.shade500,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 45),
              // First name textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'First Name',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Last name textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Last Name',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Age textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Age',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Email textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Password textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Confirm Password textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.green.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Confirm Password',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Sign up button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: GestureDetector(
                  onTap: signUp,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Have an account? Login now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Have an account? ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.showLoginPage,
                    child: Text(
                      'Login now!',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
