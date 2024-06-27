import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'history_page.dart';
import 'prediction_location_page.dart'; // Import the PredictionLocationPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = 'Loading...';
  StreamSubscription<Position>? _positionStreamSubscription;
  GoogleMapController? _mapController;
  LatLng? _initialPosition;
  List<LatLng> _routePoints = [];
  final Set<Polyline> _polylines = {};
  Marker? _currentLocationMarker;

  @override
  void initState() {
    super.initState();
    _getUserName();
    _getLocationAndUpdateInitialPosition();
  }

  Future<void> _getUserName() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.data()?['first name'] ?? 'No Name';
          });
        } else {
          setState(() {
            _userName = 'User not found';
          });
        }
      } else {
        setState(() {
          _userName = 'No user logged in';
        });
      }
    } catch (e) {
      setState(() {
        _userName = 'Error fetching user';
      });
    }
  }

  Future<void> _getLocationAndUpdateInitialPosition() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      if (await Permission.location.request().isGranted) {
        _startLocationUpdates();
      } else {
        setState(() {
          _showLocationPermissionDeniedMessage();
        });
      }
    } else if (status.isGranted) {
      _startLocationUpdates();
    }
  }

  Future<void> _startLocationUpdates() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      _routePoints.add(_initialPosition!);
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _updateLocation(position);
      });
    });
  }

  void _showLocationPermissionDeniedMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Denied'),
          content: const Text('Please enable location permissions in your device settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateLocation(Position position) async {
    LatLng newPosition = LatLng(position.latitude, position.longitude);
    _routePoints.add(newPosition);

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: PolylineId('route'),
        points: _routePoints,
        color: Colors.blue,
        width: 5,
      ),
    );

    _currentLocationMarker = Marker(
      markerId: MarkerId('currentLocation'),
      position: newPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(newPosition),
      );
    }

    // Save location to Firestore
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(userId).collection('locations').add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade500,
        title: Text(
          _userName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.history,
              color: Colors.white
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.logout, 
              color: Colors.white
            ),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Stack(
        children: [
          _initialPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition!,
                    zoom: 14.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  polylines: _polylines,
                  markers: _currentLocationMarker != null ? {_currentLocationMarker!} : {},
                ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              backgroundColor:  Colors.green.shade700,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PredictionLocationPage()),
                );
              },
              child: Icon(Icons.location_on),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        foregroundColor:  Colors.white,
        onPressed: () {
          if (_currentLocationMarker != null && _mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(_currentLocationMarker!.position),
            );
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}
