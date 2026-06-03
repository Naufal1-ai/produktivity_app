import 'dart:io' show Platform;
import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int _ongoingServiceId = 1001;
  static const int _lendingReminderId = 1002;
  static const int _ongoingTaskId = 1003;

  // Channel IDs
  static const String _ongoingChannelId = 'ongoing_service_channel';
  static const String _lendingChannelId = 'lending_channel_id';
  static const String _ongoingTaskChannelId = 'ongoing_task_channel';

  // ── Init ─────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    // Jangan jalankan di Windows/Desktop — plugin tidak mendukung
    if (!_isMobile) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _createChannels();
  }

  // ── Request permission (Android 13+ / iOS) ───────────────────────────────────
  Future<bool> requestPermission() async {
    if (!_isMobile) return false;

    if (_isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (_isIos) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // ── Create notification channels ─────────────────────────────────────────────
  void _createChannels() {
    if (!_isAndroid) return;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Ongoing/persistent channel — tidak bisa dimatikan user dari settings
    android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _ongoingChannelId,
        'Pengingat Servis Aktif',
        description:
            'Notifikasi terkunci yang menampilkan info servis motor terakhir.',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),
    );

    // Lending reminder channel
    android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _lendingChannelId,
        'Pengingat Peminjaman',
        description: 'Notifikasi pengingat tenggat peminjaman barang.',
        importance: Importance.high,
        playSound: true,
      ),
    );

    // Ongoing/persistent task channel
    android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _ongoingTaskChannelId,
        'Pengingat Task & Jadwal',
        description:
            'Notifikasi terkunci yang menampilkan tugas dan jadwal aktif.',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),
    );
  }

  // ── Ongoing / Persistent Notification ────────────────────────────────────────
  /// Menampilkan notifikasi **terkunci** di bagian atas notification shade.
  /// Tidak bisa di-swipe oleh pengguna — hanya bisa dihapus via [cancelOngoingService].
  Future<void> showOngoingServiceReminder({
    required String title,
    required String body,
    String? subText,
  }) async {
    if (!_isMobile) return;

    final androidDetails = AndroidNotificationDetails(
      _ongoingChannelId,
      'Pengingat Servis Aktif',
      channelDescription: 'Notifikasi status servis motor terkunci.',
      importance: Importance.high,
      priority: Priority.high,

      // === KUNCI UTAMA: ongoing = true → tidak bisa di-swipe ===
      ongoing: true,
      autoCancel: false,

      // Tampil di bagian atas (heads-up) saat pertama muncul
      fullScreenIntent: false,
      playSound: false,
      enableVibration: false,

      // Styling notifikasi
      styleInformation: BigTextStyleInformation(
        body,
        summaryText: subText ?? 'Tap untuk buka aplikasi',
        contentTitle: title,
        htmlFormatBigText: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),

      // Icon & warna
      color: const Color(0xFF3B82F6),
      icon: '@mipmap/ic_launcher',

      // Kategori agar muncul di bagian service/status
      category: AndroidNotificationCategory.service,

      // Visibility: tampil di lockscreen
      visibility: NotificationVisibility.public,

      subText: subText,
      showWhen: false,
      usesChronometer: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(_ongoingServiceId, title, body, details);
  }

  /// Menghapus notifikasi ongoing servis (hanya bisa dari kode, bukan user)
  Future<void> cancelOngoingService() async {
    if (!_isMobile) return;
    await _plugin.cancel(_ongoingServiceId);
  }

  // ── Ongoing Task Reminder ───────────────────────────────────────────────────
  /// Menampilkan notifikasi **terkunci** untuk Task & Jadwal.
  Future<void> showOngoingTaskReminder({
    required String title,
    required String body,
    String? subText,
  }) async {
    if (!_isMobile) return;

    final androidDetails = AndroidNotificationDetails(
      _ongoingTaskChannelId,
      'Pengingat Task & Jadwal',
      channelDescription: 'Notifikasi status task dan jadwal terkunci.',
      importance: Importance.high,
      priority: Priority.high,

      // === KUNCI UTAMA: ongoing = true → tidak bisa di-swipe ===
      ongoing: true,
      autoCancel: false,

      fullScreenIntent: false,
      playSound: false,
      enableVibration: false,

      // Styling notifikasi
      styleInformation: BigTextStyleInformation(
        body,
        summaryText: subText ?? 'Tap untuk buka aplikasi',
        contentTitle: title,
        htmlFormatBigText: false,
        htmlFormatContentTitle: false,
        htmlFormatSummaryText: false,
      ),

      // Icon & warna
      color: const Color(0xFF4F46E5), // Indigo matching modern app theme
      icon: '@mipmap/ic_launcher',

      // Kategori
      category: AndroidNotificationCategory.status,

      // Visibility: tampil di lockscreen
      visibility: NotificationVisibility.public,

      subText: subText,
      showWhen: false,
      usesChronometer: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(_ongoingTaskId, title, body, details);
  }

  /// Menghapus notifikasi ongoing task (hanya bisa dari kode, bukan user)
  Future<void> cancelOngoingTask() async {
    if (!_isMobile) return;
    await _plugin.cancel(_ongoingTaskId);
  }

  // ── Lending Reminder ─────────────────────────────────────────────────────────
  Future<void> showLendingReminder(
      String itemName, String borrowerName) async {
    if (!_isMobile) return;

    const androidDetails = AndroidNotificationDetails(
      _lendingChannelId,
      'Pengingat Peminjaman',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: false,
      autoCancel: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      _lendingReminderId,
      'Tenggat Peminjaman!',
      '$borrowerName belum mengembalikan $itemName.',
      details,
    );
  }

  // ── Cancel all ───────────────────────────────────────────────────────────────
  Future<void> cancelAll() async {
    if (!_isMobile) return;
    await _plugin.cancelAll();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  bool get _isMobile => _isAndroid || _isIos;
  bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  bool get _isIos {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }
}
