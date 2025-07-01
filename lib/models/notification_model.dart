class AppNotification {
  final int? id;
  final String title;
  final String message;
  final String date;
  final bool isRead;
  final String importance; // 'low', 'normal', 'high'

  AppNotification({
    this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.importance = 'normal',
  });

  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'title': title,
      'message': message,
      'date': date,
      'isRead': isRead ? 1 : 0,
      'importance': importance,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      date: map['date'],
      isRead: map['isRead'] == 1,
      importance: map['importance'] ?? 'normal',
    );
  }
}
