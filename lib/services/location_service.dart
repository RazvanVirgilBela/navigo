import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/location_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<LocationModel>> fetchAllUserLocations() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) => LocationModel.fromMap(doc.data())).toList();
    } else {
      return [];
    }
  }
}
