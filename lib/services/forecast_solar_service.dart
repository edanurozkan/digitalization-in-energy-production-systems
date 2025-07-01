import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';

class ForecastSolarService {
  static const String baseUrl = "https://api.forecast.solar/estimate";

  Future<Map<String, dynamic>?> getEstimatedProduction({
    required double? lat,
    required double? lon,
    required double? capacityKW,
    required double? tilt,
    required double? azimuth,
  }) async {
    try {
      if (lat == null ||
          lon == null ||
          capacityKW == null ||
          tilt == null ||
          azimuth == null) {
        print("HATA: Parametreler null olamaz");
        return null;
      }

      if (capacityKW <= 0) {
        print("HATA: Capacity sıfırdan büyük olmalı");
        return null;
      }

      final url = Uri.parse(
          "$baseUrl/${lat.toStringAsFixed(6)}/${lon.toStringAsFixed(6)}/${tilt}/${azimuth}/${capacityKW.toStringAsFixed(2)}");

      print("API request URL: $url");

      final ioc = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      final client = IOClient(ioc);
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("✅ API Response Data: ${response.body}");

       
        double latestDaily = 0.0;
        if (data['result'].containsKey('watt_hours_day')) {
          final dailyMap =
              data['result']['watt_hours_day'] as Map<String, dynamic>;
          final sortedKeys = dailyMap.keys.toList()..sort();
          final latestDate = sortedKeys.last;
          latestDaily = (dailyMap[latestDate] as num).toDouble() / 1000;
        }

        
        Map<int, double> hourlyMapCleaned = {};
        if (data['result'].containsKey('watt_hours_period')) {
          final rawHourlyMap =
              data['result']['watt_hours_period'] as Map<String, dynamic>;

          final allDates = rawHourlyMap.keys
              .map((key) => key.substring(0, 10))
              .toSet()
              .toList()
            ..sort();
          final latestDate = allDates.last;

          rawHourlyMap.forEach((timestamp, value) {
            if (timestamp.startsWith(latestDate)) {
              try {
                final utc = DateTime.parse(timestamp);
                final local = utc.toLocal();
                final hour = local.hour;
                if (value is num) {
                  hourlyMapCleaned[hour] = value.toDouble() / 1000;
                }
              } catch (_) {}
            }
          });
        }

        return {
          'daily': latestDaily,
          'hourly': hourlyMapCleaned, // Map<int, double>
        };
      } else {
        print("API Error [${response.statusCode}]: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Beklenmeyen Hata: $e");
      return null;
    }
  }
}
