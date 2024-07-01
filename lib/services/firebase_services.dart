// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> addUserData(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(uid).set(userData);
  }

  Future<QuerySnapshot> getUserLocations(String uid, DateTime start, DateTime end) async {
    return await _firestore
        .collection('users')
        .doc(uid)
        .collection('locations')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .orderBy('timestamp', descending: false)
        .get();
  }
}
