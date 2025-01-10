import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../common/common.dart';
import '../model/check_in_check_out_response.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check for location permissions.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current position.
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<bool> _showLocationServiceDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Services Disabled'),
            content: const Text(
                'Location services are disabled. Please enable them in settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<String> getAddress(double latitude, double longitude) async {
    try {
      debugPrint("latitude:$latitude longitude:$longitude");
      // Get the list of place mark for the coordinates
      List<Placemark> placeMark =
          await placemarkFromCoordinates(latitude, longitude);
      debugPrint("placeMark:${placeMark.length}");
      // Get the first place mark
      Placemark place = placeMark.first;
      debugPrint(
          "address : ${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}, ${place.isoCountryCode}");
      // Format the address
      return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}, ${place.isoCountryCode}';
    } catch (e) {
      debugPrint('Error occurred while get address: $e');
      debugPrintStack();
      return '';
    }
  }

  Future<String> getAddressFromLocation() async {
    // Check for permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return '';
      }
    }

    // Get the current location
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Fetch address details from latitude and longitude
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}, ${place.postalCode}';
        debugPrint("address : $address");
        return address;
      } else {
        debugPrint("No address found for the given coordinates.");
        return '';
      }
    } catch (e) {
      debugPrint("Error occurred while getting address: $e");
      return '';
    }
  }

  // Function to send the location to the server
  Future<void> sendLocationToServer(
      int executiveId, int enteredBy, String token) async {
    try {
      // Fetch the current location
      Position position = await getCurrentLocation();
      double latitude = position.latitude;
      double longitude = position.longitude;

      CheckInCheckOutService service = CheckInCheckOutService();

      String executiveLocationXml =
          "<DocumentElement><ExecutiveLocation><DateTime>${getCurrentDateTimeWithSecond()}</DateTime><Lat>$latitude</Lat><Long>$longitude</Long></ExecutiveLocation></DocumentElement>";

      CheckInCheckOutResponse responseData =
          await service.fetchExecutiveLocation(
              executiveId, enteredBy, executiveLocationXml, token);

      if (responseData.status == 'Success') {
        String msgType = responseData.success.msgType;
        String msgText = responseData.success.msgText;
        if (msgType.isNotEmpty && msgType == 's') {
          debugPrint(msgText);
        } else if (msgType.isNotEmpty && msgType == 'e') {
          debugPrint('Failed to send location : $msgText');
        } else {
          debugPrint('Failed to send location $msgType $msgText');
        }
      } else {
        debugPrint('Failed to send location ${responseData.status}');
      }
    } catch (e) {
      debugPrint('Error fetching or sending location: $e');
    }
  }
}
