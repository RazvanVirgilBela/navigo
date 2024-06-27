import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class PredictionLocationPage extends StatefulWidget {
  const PredictionLocationPage({Key? key}) : super(key: key);

  @override
  _PredictionLocationPageState createState() => _PredictionLocationPageState();
}

class _PredictionLocationPageState extends State<PredictionLocationPage> {
  GoogleMapController? _mapController;
  List<LatLng> _predictedLocations = [];
  final Set<Marker> _markers = {};
  List<LatLng> _historicalLocations = [];
  List<DateTime> _timestamps = [];
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _fetchHistoricalLocations();
    _getCurrentLocation();
  }

  Future<void> _fetchHistoricalLocations() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('locations')
          .orderBy('timestamp', descending: false)
          .get();

      List<LatLng> points = snapshot.docs.map((doc) {
        return LatLng(doc.data()['latitude'], doc.data()['longitude']);
      }).toList();

      List<DateTime> timestamps = snapshot.docs.map((doc) {
        return (doc.data()['timestamp'] as Timestamp).toDate();
      }).toList();

      setState(() {
        _historicalLocations = points;
        _timestamps = timestamps;
        _predictFutureLocations();
      });
    }
  }

  void _predictFutureLocations() {
    DateTime now = DateTime.now();
    const double clusterRadius = 0.01; // Approx 1 km
    const int minPoints = 3;

    List<LatLng> clusters = _clusterLocations(_historicalLocations, clusterRadius, minPoints);

    // Filter clusters by timestamp to match approximately the current time
    List<LatLng> timeFilteredLocations = [];
    for (int i = 0; i < _historicalLocations.length; i++) {
      if (_isTimeApproxEqual(_timestamps[i], now)) {
        timeFilteredLocations.add(_historicalLocations[i]);
      }
    }

    setState(() {
      _predictedLocations = [...clusters, ...timeFilteredLocations];
      _setMarkers();
      _showAllPoints();
    });
  }

  bool _isTimeApproxEqual(DateTime timestamp1, DateTime timestamp2) {
    return timestamp1.hour == timestamp2.hour && timestamp1.minute == timestamp2.minute;
  }

  List<LatLng> _clusterLocations(List<LatLng> locations, double radius, int minPoints) {
    List<LatLng> clusters = [];
    Set<int> visited = {};

    for (int i = 0; i < locations.length; i++) {
      if (visited.contains(i)) continue;

      List<int> cluster = _rangeQuery(locations, i, radius);
      if (cluster.length >= minPoints) {
        clusters.add(_calculateCentroid(locations, cluster));
        visited.addAll(cluster);
      }
    }

    return clusters;
  }

  List<int> _rangeQuery(List<LatLng> locations, int index, double radius) {
    List<int> neighbors = [];
    for (int i = 0; i < locations.length; i++) {
      if (_distance(locations[index], locations[i]) <= radius) {
        neighbors.add(i);
      }
    }
    return neighbors;
  }

  double _distance(LatLng a, LatLng b) {
    double latDiff = a.latitude - b.latitude;
    double lngDiff = a.longitude - b.longitude;
    return sqrt(latDiff * latDiff + lngDiff * lngDiff);
  }

  LatLng _calculateCentroid(List<LatLng> locations, List<int> cluster) {
    double lat = 0;
    double lng = 0;
    for (int index in cluster) {
      lat += locations[index].latitude;
      lng += locations[index].longitude;
    }
    return LatLng(lat / cluster.length, lng / cluster.length);
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _setMarkers();
    });
  }

  void _setMarkers() {
    _markers.clear();
    for (var location in _predictedLocations) {
      _markers.add(Marker(
        markerId: MarkerId(location.toString()),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: 'Predicted Location', snippet: 'Based on your history'),
      ));
    }
    if (_currentLocation != null) {
      _markers.add(Marker(
        markerId: MarkerId('currentLocation'),
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Current Location'),
      ));
    }
    setState(() {});
  }

  void _showAllPoints() {
    if (_mapController == null || (_predictedLocations.isEmpty && _currentLocation == null)) return;

    LatLngBounds bounds;
    List<LatLng> allPoints = [..._predictedLocations];
    if (_currentLocation != null) {
      allPoints.add(_currentLocation!);
    }

    if (allPoints.length == 1) {
      bounds = LatLngBounds(
        southwest: allPoints[0],
        northeast: allPoints[0],
      );
    } else {
      double x0 = allPoints[0].latitude;
      double x1 = allPoints[0].latitude;
      double y0 = allPoints[0].longitude;
      double y1 = allPoints[0].longitude;

      for (LatLng point in allPoints) {
        if (point.latitude > x1) x1 = point.latitude;
        if (point.latitude < x0) x0 = point.latitude;
        if (point.longitude > y1) y1 = point.longitude;
        if (point.longitude < y0) y0 = point.longitude;
      }

      bounds = LatLngBounds(
        southwest: LatLng(x0, y0),
        northeast: LatLng(x1, y1),
      );
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade500,
        leading: IconButton(
          icon: const Icon(
            Icons.home,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous page or homepage
          },
        ),
        title: Text(
          'Predicted Locations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
      body: GoogleMap(
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        initialCameraPosition: CameraPosition(
          target: _predictedLocations.isNotEmpty ? _predictedLocations[0] : LatLng(0, 0),
          zoom: 10.0,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          WidgetsBinding.instance?.addPostFrameCallback((_) => _showAllPoints());
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        onPressed: _showAllPoints,
        child: Icon(Icons.zoom_out_map),
      ),
    );
  }
}
