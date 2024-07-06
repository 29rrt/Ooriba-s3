import 'package:location/location.dart';

class LocationService {
  final Location _locationService = Location();

  Future<LocationData> getCurrentLocation() async {
    return await _locationService.getLocation();
  }
}
