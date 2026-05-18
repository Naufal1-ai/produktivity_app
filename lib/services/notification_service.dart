import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  /// Menjadwalkan notifikasi peringatan barang
  /// Catatan: Anda perlu menginstal plugin `timezone` untuk scheduling yang presisi di masa depan.
  /// Ini adalah stub dasar pemanggilan notifikasi langsung.
  Future<void> showLendingReminder(String itemName, String borrowerName) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lending_channel_id',
      'Pengingat Peminjaman',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(0, 'Tenggat Peminjaman!',
        '$borrowerName belum mengembalikan $itemName.', details);
  }
}
