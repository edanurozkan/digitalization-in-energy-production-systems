import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/notification_model.dart';
import '../theme/theme.dart';
import '../utils/notifications_helper.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AppNotification> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkForMaintenanceNotifications();
    loadNotifications();
    insertMockNotifications();
  }

  Future<void> insertMockNotifications() async {
    final now = DateTime.now();

    await DBHelper.insertNotification(AppNotification(
      title: "Bakım Uyarısı",
      message: "Panelinizin bakımı üzerinden 30 gün geçti.",
      date: now.toIso8601String(),
      isRead: false,
      importance: 'high',
    ));

    await DBHelper.insertNotification(AppNotification(
      title: "Eğim Açısı Bilgisi",
      message: "Tilt açınız optimum değerden biraz sapmış olabilir.",
      date: now.toIso8601String(),
      isRead: false,
      importance: 'medium',
    ));

    await DBHelper.insertNotification(AppNotification(
      title: "Verimlilik Bilgisi",
      message: "Sistemin verimliliği genel olarak stabil.",
      date: now.toIso8601String(),
      isRead: true,
      importance: 'low',
    ));
  }

  Future<void> loadNotifications() async {
    final all = await DBHelper.getAllNotifications();
    setState(() {
      notifications = all;
      isLoading = false;
    });
  }

  Future<void> markAsRead(int id) async {
    await DBHelper.markAsRead(id);
    await loadNotifications();
  }

  Color _getImportanceColor(String importance) {
    switch (importance) {
      case 'high':
        return const Color.fromARGB(255, 246, 213, 170); // Sarımsı
      case 'medium':
        return const Color(0xFFFFF3CD); // Yumuşak sarı-yeşil
      case 'low':
      default:
        return const Color.fromARGB(255, 211, 249, 181); // Yeşilimsi
    }
  }

  IconData _getImportanceIcon(String importance) {
    switch (importance) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.warning_amber;
      case 'low':
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bildirimler'),
        centerTitle: true,
        backgroundColor: AppColors.card,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    "Henüz bildirim yok.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final noti = notifications[index];
                    final formattedDate = DateFormat('dd MMM yyyy - HH:mm')
                        .format(DateTime.parse(noti.date));

                    return GestureDetector(
                      onTap: () => markAsRead(noti.id!),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _getImportanceColor(noti.importance),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              _getImportanceIcon(noti.importance),
                              color: noti.isRead
                                  ? Colors.grey
                                  : Colors.green.shade700,
                            ),
                          ),
                          title: Text(
                            noti.title,
                            style: TextStyle(
                              fontWeight: noti.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                noti.message,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          trailing: noti.isRead
                              ? const Icon(Icons.check, color: Colors.grey)
                              : const Icon(Icons.fiber_manual_record,
                                  color: Colors.green, size: 16),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
