import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ml_linalg/linalg.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../utils/kmeans.dart';

class PredictionLocationPage extends StatefulWidget {
  const PredictionLocationPage({Key? key}) : super(key: key);

  @override
  _PredictionLocationPageState createState() => _PredictionLocationPageState();
}

class _PredictionLocationPageState extends State<PredictionLocationPage> {
  GoogleMapController? _mapController;
  List<LatLng> _predictedLocations = [];
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;
  bool isConnected = false;
  String connectionMessage = "Checking connection...";

  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _fetchPredictedLocations();
    _getCurrentLocation();
  }

  Future<void> _fetchPredictedLocations() async {
    try {
      List<LocationModel> allLocations = await _locationService.fetchAllUserLocations();

      if (allLocations.isNotEmpty) {
        List<LocationModel> filteredLocations = _filterLocationsByTime(allLocations);
        setState(() {
          _predictedLocations = _predictFutureLocations(filteredLocations);
          _setMarkers();
          connectionMessage = "Connection successful";
          isConnected = true;
        });
      } else {
        setState(() {
          connectionMessage = "No locations found";
          isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        connectionMessage = "Failed to fetch locations: $e";
        isConnected = false;
      });
    }
  }

  List<LocationModel> _filterLocationsByTime(List<LocationModel> locations) {
    DateTime now = DateTime.now();
    int currentMinutes = now.hour * 60 + now.minute;

    return locations.where((location) {
      DateTime timestamp = location.timestamp;
      int locationMinutes = timestamp.hour * 60 + timestamp.minute;

      return (locationMinutes >= currentMinutes - 30) && (locationMinutes <= currentMinutes + 30);
    }).toList();
  }

  List<LatLng> _predictFutureLocations(List<LocationModel> locations) {
    final data = Matrix.fromRows(locations.map((loc) => Vector.fromList([loc.latitude, loc.longitude])).toList());
    
    final kMeans = KMeans(data.rows.toList(), 3);
    final centroids = kMeans.centroids;

    return centroids.map((centroid) => LatLng(centroid[0], centroid[1])).toList();
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
        infoWindow: InfoWindow(
          title: 'Predicted Location',
          snippet: 'Based on your history',
          onTap: () => _showDistanceToCurrentLocation(location),
        ),
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

  void _showDistanceToCurrentLocation(LatLng location) {
    if (_currentLocation == null) return;

    double distance = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      location.latitude,
      location.longitude,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Distance to Location'),
          content: Text('Distance: ${distance.toStringAsFixed(2)} meters'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
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
        title: const Text(
          'Predicted Locations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        actions: [
          Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_off,
            color: isConnected ? Colors.green : Colors.red,
          ),
        ],
      ),
      body: Column(
        children: [
          Text(connectionMessage),
          Expanded(
            child: GoogleMap(
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        onPressed: _showAllPoints,
        child: const Icon(Icons.zoom_out_map),
      ),
    );
  }
}
