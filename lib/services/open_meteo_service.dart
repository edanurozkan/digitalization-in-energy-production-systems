

import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenMeteoService {

  static Future<String?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude&longitude=$longitude'
        '&current=temperature_2m,weather_code');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = data['current']['temperature_2m'];
        final weatherCode = data['current']['weather_code'];

        String condition = _mapWeatherCode(weatherCode);
        return "$condition, ${temp.toStringAsFixed(1)}°C";
      } else {
        print("Weather error: ${response.statusCode}");
      }
    } catch (e) {
      print("Weather exception: $e");
    }
    return null;
  }

  /// 🔹 Hava durumu kodunu emoji + metin olarak yorumla
  static String _mapWeatherCode(int code) {
    switch (code) {
      case 0:
        return "Clear Sky ☀️";
      case 1:
      case 2:
      case 3:
        return "Partly Cloudy 🌤️";
      case 45:
      case 48:
        return "Fog 🌫️";
      case 51:
      case 53:
      case 55:
        return "Drizzle 🌦️";
      case 61:
      case 63:
      case 65:
        return "Rain 🌧️";
      case 71:
      case 73:
      case 75:
        return "Snow 🌨️";
      case 95:
        return "Thunderstorm ⛈️";
      default:
        return "Unknown";
    }
  }

  /// 🔸 Gelişmiş model: haftalık tahmini üretim hesapla (kWh)
  static Future<List<double>> getWeeklySolarEstimate({
    required double lat,
    required double lon,
    required double capacityKW,
    required double tilt,
    required double azimuth,
  }) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&daily=shortwave_radiation_sum,cloudcover_mean,temperature_2m_max'
      '&timezone=auto',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Open-Meteo data');
    }

    final data = json.decode(response.body);
    final List radiationList =
        data['daily']['shortwave_radiation_sum'] ?? List.filled(7, 0.0);
    final List cloudList =
        data['daily']['cloudcover_mean'] ?? List.filled(7, 0.0);
    final List tempList =
        data['daily']['temperature_2m_max'] ?? List.filled(7, 25.0);

    List<double> result = [];

    for (int i = 0; i < radiationList.length && i < 7; i++) {
      final radiation = (radiationList[i] as num).toDouble(); // kWh/m²
      final cloudcover = (cloudList[i] as num).toDouble(); // % mean
      final temp = (tempList[i] as num).toDouble(); // °C

      // 1️⃣ Base Performance Ratio
      double pr = 0.80;

      // 2️⃣ Cloudcover etkisi (max %20 düşüş)
      pr -= (cloudcover / 100) * 0.20;

      // 3️⃣ Sıcaklık etkisi (>35°C için -%5)
      if (temp > 35) pr -= 0.05;

      // 4️⃣ Tilt verim faktörü
      double optimalTilt = lat;
      double tiltEff = 1.0 - ((optimalTilt - tilt).abs() / 90.0);

      // 5️⃣ Azimuth verim faktörü
      double azimuthEff = 1.0 - ((180 - azimuth).abs() / 180.0);

      // 6️⃣ PR güncellemesi
      pr *= tiltEff;
      pr *= azimuthEff;

      // 7️⃣ PR sınırla
      pr = pr.clamp(0.65, 0.78);

      // 8️⃣ Tahmini üretim
      final estimatedKWh = capacityKW * radiation * pr;
      result.add(double.parse(estimatedKWh.toStringAsFixed(2)));
    }

    return result;
  }

  /// 🔹 Bildirimler için sadeleştirilmiş hava durumu bilgisi
  static Future<Map<String, dynamic>?> getCurrentWeatherCode(
      double lat, double lon) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,weather_code',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        final code = current['weather_code'];
        final temp = current['temperature_2m'];
        final desc = _mapWeatherCode(code); // mevcut fonksiyonla uyumlu

        return {
          'code': code,
          'temp': temp,
          'desc': desc,
        };
      } else {
        print("Weather code fetch failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Weather fetch exception: $e");
    }
    return null;
  }
}
