import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:location/location.dart' as per;

class MyMapWidget extends StatefulWidget {
  final Function(String address)? onAddressSelected;

  const MyMapWidget({
    super.key,
    this.onAddressSelected,
  });

  @override
  MyMapWidgetState createState() => MyMapWidgetState();
}

class MyMapWidgetState extends State<MyMapWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _isLoading = true; // Loader flag
  final Set<Marker> _markers = {};
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  // Initialize map by fetching the current location
  Future<void> _initializeMap() async {
    try {
      final location = loc.Location();
      await _checkLocationService(location);
      await _getCurrentLocation(location);
    } catch (e) {
      debugPrint('Error initializing map: $e');
    } finally {
      _stopLoading();
    }
  }

  // Check and request location permissions
  Future<void> _checkLocationService(loc.Location location) async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) throw Exception("Location service disabled.");
    }

    per.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == per.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != per.PermissionStatus.granted) {
        throw Exception("Location permission denied.");
      }
    }
  }

// Get the current location and update the marker and camera
  Future<void> _getCurrentLocation(loc.Location location) async {
    final currentLocation = await location.getLocation();
    _currentLocation =
        LatLng(currentLocation.latitude!, currentLocation.longitude!);

    try {
      // Fetch the address from coordinates
      final address = await _getAddressFromLatLng(_currentLocation!);
      _updateMarker(_currentLocation!, address);

      // Trigger the address callback only if the address is valid
      if (address.isNotEmpty && address != "Unknown Address") {
        widget.onAddressSelected?.call(address);
      }
    } catch (e) {
      debugPrint('Error fetching address for current location: $e');
      _updateMarker(_currentLocation!, "Unknown Address");
    }

    _moveCamera(_currentLocation!, 14.0);
  }

  // Update marker on the map
  void _updateMarker(LatLng position, String title) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('locationMarker'),
          position: position,
          infoWindow: InfoWindow(title: title),
        ),
      );
    });
  }

  // Animate the camera to a specific position
  Future<void> _moveCamera(LatLng position, double zoom) async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
    );
  }

  // Stop the loading spinner
  void _stopLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  // Handle map tap to select a new location
  Future<void> _onMapTap(LatLng position) async {
    try {
      final address = await _getAddressFromLatLng(position);
      _updateMarker(position, address);

      // Call onAddressSelected only if a valid address is found
      if (address.isNotEmpty && address != "Unknown Address") {
        widget.onAddressSelected?.call(address);
      }
    } catch (e) {
      debugPrint('Error fetching address for selected location: $e');
      _updateMarker(position, "Unknown Address");
      // Do not call onAddressSelected if there's an error
    }

    _moveCamera(position, 14.0);
  }

  // Convert LatLng to an address string
  Future<String> _getAddressFromLatLng(LatLng position) async {
    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isEmpty) return 'Unknown Address';
    final place = placemarks.first;
    return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
  }

  // Set an address and update the map
  Future<void> setAddress(String address) async {
    _startLoading();

    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final position =
        LatLng(locations.first.latitude, locations.first.longitude);
        _updateMarker(position, address);
        _moveCamera(position, 14.0);

        // Call onAddressSelected only if a valid address is set
        // widget.onAddressSelected?.call(address);
      }
    } catch (e) {
      debugPrint('Error setting address: $e');
      // Do not call onAddressSelected if there's an error
    } finally {
      _stopLoading();
    }
  }

  // Start the loading spinner
  void _startLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300.0,
      decoration: BoxDecoration(
        border: Border.all(width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onVerticalDragUpdate: (details) {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: GoogleMap(
              initialCameraPosition:
                  const CameraPosition(target: LatLng(0, 0), zoom: 12.0),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              onTap: _onMapTap,
              gestureRecognizers: Set()
                ..add(Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer())),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
