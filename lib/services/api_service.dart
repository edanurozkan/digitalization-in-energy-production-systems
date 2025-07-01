import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/energy_production_model.dart';
import '../database/db_helper.dart';

class ApiService {
  final String _baseUrl = 'https://developer.nrel.gov/api/pvwatts/v6.json';
  final String _apiKey = 'hJas9wq469fEqVEUzOossyq54GP21dcmghosyMvC';

  Future<Map<String, dynamic>?> fetchPvData({
    required double lat,
    required double lon,
    required double systemCapacity,
    double tilt = 30,
    double azimuth = 180,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'api_key': _apiKey,
        'lat': lat.toString(),
        'lon': lon.toString(),
        'system_capacity': systemCapacity.toString(),
        'azimuth': azimuth.toString(),
        'tilt': tilt.toString(),
        'array_type': '1',
        'module_type': '1',
        'losses': '10',
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['outputs'];
      } else {
        print('API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception occurred: $e');
      return null;
    }
  }

  Future<void> saveMonthlyProductionToDB({
    required List monthlyData,
    required int systemId,
    required int year,
  }) async {
    for (int i = 0; i < monthlyData.length; i++) {
      final production = EnergyProduction(
        systemId: systemId,
        month: i + 1,
        year: year,
        energyKWh: monthlyData[i],
      );
      await DBHelper.insertEnergyProduction(production);
    }
  }

  Future<double?> fetchDailyEnergy({
    required double lat,
    required double lon,
    required double systemCapacity,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'api_key': _apiKey,
        'lat': lat.toString(),
        'lon': lon.toString(),
        'system_capacity': systemCapacity.toString(),
        'azimuth': '180',
        'tilt': '30',
        'array_type': '1',
        'module_type': '1',
        'losses': '10',
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['outputs']['ac_annual'] ?? 0) / 365;
      }
    } catch (e) {
      print('Daily fetch error: $e');
    }
    return null;
  }

  Future<bool> checkCloudyTomorrow({
    required double lat,
    required double lon,
  }) async {
    try {
      final uri = Uri.parse('https://api.open-meteo.com/v1/forecast')
          .replace(queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'daily': 'cloudcover',
        'timezone': 'auto',
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clouds = data['daily']['cloudcover'];
        if (clouds != null && clouds.length >= 2) {
          return clouds[1] > 80; // yarın için
        }
      }
    } catch (e) {
      print('Weather fetch error: $e');
    }
    return false;
  }
}
