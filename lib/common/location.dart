import 'package:geocoding/geocoding.dart';

String buildAddress(List<Placemark> placemarks) {
  if (placemarks.isEmpty) {
    return 'Unknown Address';
  }

  Placemark place = placemarks[0];
  String address = '';

  // Dynamically building the address
  if (place.name != null && place.name!.isNotEmpty) {
    address += place.name!;
  }
  if (place.street != null &&
      place.street!.isNotEmpty &&
      address != place.street &&
      place.locality != place.name) {
    address += ', ${place.street!}';
  }
  if (place.subLocality != null &&
      place.subLocality!.isNotEmpty &&
      address != place.subLocality &&
      place.locality != place.street &&
      place.locality != place.subLocality) {
    address += ', ${place.subLocality!}';
  }
  if (place.locality != null &&
      place.locality!.isNotEmpty &&
      place.locality != place.name &&
      place.locality != place.street) {
    address += ', ${place.locality!}';
  }
  if (place.administrativeArea != null &&
      place.administrativeArea!.isNotEmpty) {
    address += ', ${place.administrativeArea!}';
  }
  if (place.country != null && place.country!.isNotEmpty) {
    address += ', ${place.country!}';
  }
  if (place.postalCode != null && place.postalCode!.isNotEmpty) {
    address += ', ${place.postalCode!}';
  }

  // Remove trailing comma if it exists
  return address.endsWith(', ')
      ? address.substring(0, address.length - 2)
      : address;
}