import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationHelper {
  // Singleton pattern to ensure only one instance of LocationHelper
  LocationHelper._privateConstructor();
  static final LocationHelper instance = LocationHelper._privateConstructor();

  // Function to get the current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          throw Exception('Location permissions are denied.');
        }
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      // You can handle the error or rethrow it depending on your needs
      return null;
    }
  }
}
