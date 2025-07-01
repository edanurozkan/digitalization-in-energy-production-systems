import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/notification_model.dart';
import '../services/open_meteo_service.dart';


Future<void> checkForMaintenanceNotifications() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId');

  if (userId == null) return;

  final systems = await DBHelper.getSystemsByUserId(userId);

  for (var system in systems) {
    final createdAtStr = system['created_at'];
    if (createdAtStr == null) continue;

    final createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) continue;

    final now = DateTime.now();
    final daysPassed = now.difference(createdAt).inDays;

    if (daysPassed >= 30) {
      final systemName = system['system_name'] ?? 'Unnamed System';

      // Aynı bildirim daha önce eklenmiş mi kontrol et (isteğe bağlı: tarih veya sistem adına göre)
      final existing = await DBHelper.getAllNotifications();
      final alreadyExists = existing.any((n) =>
          n.title.contains('Maintenance') &&
          n.message.contains(systemName) &&
          !n.isRead);

      if (!alreadyExists) {
        final notification = AppNotification(
          title: "Maintenance Reminder",
          message:
              "It's been $daysPassed days since you installed $systemName. Please check the panels for maintenance.",
          date: DateFormat('yyyy-MM-dd HH:mm').format(now),
          isRead: false,
          importance: "medium",
        );
        await DBHelper.insertNotification(notification);
      }
    }
  }
}

Future<void> checkForWeatherAlerts() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId');
  if (userId == null) return;

  final systems = await DBHelper.getSystemsByUserId(userId);
  final existing = await DBHelper.getAllNotifications();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  for (var system in systems) {
    final lat = system['latitude'];
    final lon = system['longitude'];
    final systemName = system['system_name'] ?? 'Unnamed System';

    final weather = await OpenMeteoService.getCurrentWeatherCode(lat, lon);
    if (weather == null) continue;

    final code = weather['code'];
    final temp = weather['temp'];
    final desc = weather['desc'];

    // Sadece tehlikeli kodlar:
    if (code == 61 || code == 63 || code == 65 || code == 95) {
      final alreadyExists = existing.any((n) =>
          n.title == "⚠️ Hava Durumu Uyarısı" &&
          n.message.contains(systemName) &&
          n.date.startsWith(today));

      if (!alreadyExists) {
        final notification = AppNotification(
          title: "⚠️ Hava Durumu Uyarısı",
          message:
              "$systemName panelinin bulunduğu bölgede bugün $desc ($temp°C) bekleniyor. Üretimde azalma olabilir.",
          date: DateTime.now().toIso8601String(),
          isRead: false,
          importance: "high",
        );
        await DBHelper.insertNotification(notification);
      }
    }
  }
}

Future<void> checkForTiltAzimuthSuggestions() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('userId');
  if (userId == null) return;

  final systems = await DBHelper.getSystemsByUserId(userId);

  for (final system in systems) {
    final name = system['system_name'] ?? 'Sistem';
    final latitude = (system['latitude'] as num).toDouble();
    final tilt = (system['tilt'] as num).toDouble();
    final azimuth = (system['azimuth'] as num).toDouble();

    final optimalTilt = latitude;
    final tiltDeviation = (optimalTilt - tilt).abs();
    final azimuthDeviation = (180 - azimuth).abs();

    final tiltThreshold = 15.0;
    final azimuthThreshold = 30.0;

    if (tiltDeviation > tiltThreshold || azimuthDeviation > azimuthThreshold) {
      final message =
          "$name sisteminin panel açısı optimizasyon dışı olabilir. Performans artışı için tilt (${tilt.toInt()}°) veya azimuth (${azimuth.toInt()}°) değerlerini kontrol edin.";

      await DBHelper.insertNotification(AppNotification(
        title: "📐 Panel Açısı Optimizasyonu",
        message: message,
        date: DateTime.now().toIso8601String(),
        isRead: false,
        importance: 'medium',
      ));
    }
  }
}


