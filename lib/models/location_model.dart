import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationModel.fromMap(Map<String, dynamic> data) {
    return LocationModel(
      latitude: data['latitude'],
      longitude: data['longitude'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }
}