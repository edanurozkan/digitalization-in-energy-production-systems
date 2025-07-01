import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _apiKey = "8582514e127c4d79912c3c379e4c3831";
  static const String _baseUrl = "https://api.opencagedata.com/geocode/v1/json";

  static Future<String?> getLocationName(
      {required double latitude, required double longitude}) async {
    final url =
        Uri.parse("$_baseUrl?q=$latitude+$longitude&key=$_apiKey&language=en");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'];
        if (results != null && results.isNotEmpty) {
          final components = results[0]['components'];
          final city = components['city'] ??
              components['town'] ??
              components['village'] ??
              '';
          final country = components['country'] ?? '';
          return "$city, $country";
        }
      } else {
        print("Reverse Geocoding API error: ${response.statusCode}");
      }
    } catch (e) {
      print("Reverse Geocoding Exception: $e");
    }
    return null;
  }
}
