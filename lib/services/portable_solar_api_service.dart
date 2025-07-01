import 'dart:convert';
import 'package:http/http.dart' as http;

class PortableSolarApiService {
  final String apiKey = 'AIzaSyDME9cdP9TcgRIkWS_Rvf4b8jShkdxD7Bc';

  Future<List<DailySolarForecast>> fetchSolarForecast(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> list = json['list'];

      Map<String, List<Map<String, dynamic>>> dailyData = {};

      // Verileri günlere göre gruplandır
      for (var item in list) {
        String date = item['dt_txt'].substring(0, 10);
        if (!dailyData.containsKey(date)) {
          dailyData[date] = [];
        }
        dailyData[date]!.add(item);
      }

      List<DailySolarForecast> result = [];

      for (var entry in dailyData.entries.take(5)) {
        final values = entry.value;
        double avgCloud = values
                .map((e) => e['clouds']['all'] as num)
                .reduce((a, b) => a + b) /
            values.length;

        
        double estimatedSunHours = 8 * ((100 - avgCloud) / 100); // 8 saat max

        result.add(DailySolarForecast(
          date: entry.key,
          cloudiness: avgCloud,
          sunHours: estimatedSunHours,
        ));
      }

      return result;
    } else {
      throw Exception('Failed to fetch forecast data');
    }
  }
}

class DailySolarForecast {
  final String date;
  final double cloudiness;
  final double sunHours;

  DailySolarForecast({
    required this.date,
    required this.cloudiness,
    required this.sunHours,
  });
}
