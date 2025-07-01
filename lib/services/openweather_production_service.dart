// lib/services/openweather_production_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenWeatherProductionService {
  final String apiKey = 'f22cae0dc73de9f12f6606a6f3b3c4f3'; // 🔁 Aynı şekilde doldur

  Future<List<double>?> getPanelForecast(String panelId) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/3.0/solar_pv/panels/$panelId/energy?appid=$apiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // Burada saatlik verileri çekiyoruz (örnek format)
        final List<dynamic> hourly = json['generation']['forecast'] ?? [];

        return hourly.map((e) => double.tryParse(e.toString()) ?? 0.0).toList();
      } else {
        print("❌ Üretim verisi çekme hatası: ${response.statusCode}");
        print("Yanıt: ${response.body}");
      }
    } catch (e) {
      print("❌ GET panel üretim istisnası: $e");
    }

    return null;
  }
}
