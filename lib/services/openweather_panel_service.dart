
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenWeatherPanelService {
  final String apiKey =
      'f22cae0dc73de9f12f6606a6f3b3c4f3'; 

  Future<String?> createPanel({
    required double latitude,
    required double longitude,
    required double capacityKW,
  }) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/3.0/solar_pv/panels?appid=$apiKey',
    );

    final body = {
      "name": "UserPanel",
      "location": {"lat": latitude, "lon": longitude},
      "capacity": capacityKW,
      "azimuth": 180,
      "tilt": 30,
      "area": capacityKW * 5,
      "module_type": "standard",
      "tracking": "fixed",
      "system_loss": 0.15
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return json['id']; // ✅ başarılı panelId
      } else {
        print("❌ Panel oluşturma hatası: ${response.statusCode}");
        print("Yanıt: ${response.body}");
      }
    } catch (e) {
      print("❌ Panel oluşturma istisnası: $e");
    }

    return null;
  }
}
