import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:productivity/data/models/vehicle_service_model.dart';
import 'package:productivity/services/notification_service.dart';

/// Provider untuk mengatur state notifikasi persisten servis kendaraan.
/// Persists the toggle state across app restarts using SharedPreferences.
class NotificationSettingsProvider extends ChangeNotifier {
  static const String _prefKeyServiceReminder = 'pref_service_reminder_enabled';

  bool _serviceReminderEnabled = false;
  bool _permissionGranted = false;

  // Cache to prevent redundant notification IPC calls
  String? _lastShownTitle;
  String? _lastShownBody;
  String? _lastShownSubText;
  bool _lastShownWasOngoing = false;

  bool get serviceReminderEnabled => _serviceReminderEnabled;
  bool get permissionGranted => _permissionGranted;

  NotificationSettingsProvider() {
    _loadPrefs();
  }

  // ── Load saved preference ─────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _serviceReminderEnabled =
        prefs.getBool(_prefKeyServiceReminder) ?? false;
    notifyListeners();
  }

  // ── Toggle service reminder ON/OFF ────────────────────────────────────────
  Future<void> setServiceReminder({
    required bool enabled,
    List<VehicleServiceModel>? services,
  }) async {
    // Minta permission jika belum pernah
    if (enabled && !_permissionGranted) {
      final granted = await NotificationService().requestPermission();
      _permissionGranted = granted;
      if (!granted) {
        // Jika user menolak izin, jangan aktifkan
        notifyListeners();
        return;
      }
    }

    _serviceReminderEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyServiceReminder, enabled);

    if (enabled && services != null && services.isNotEmpty) {
      await _showNotification(services.first);
    } else {
      _lastShownWasOngoing = false;
      _lastShownTitle = null;
      _lastShownBody = null;
      _lastShownSubText = null;
      await NotificationService().cancelOngoingService();
    }

    notifyListeners();
  }

  // ── Update notifikasi saat data servis berubah ────────────────────────────
  Future<void> updateServiceReminder(List<VehicleServiceModel> services) async {
    if (!_serviceReminderEnabled) return;
    if (services.isEmpty) {
      if (_lastShownWasOngoing) {
        _lastShownWasOngoing = false;
        _lastShownTitle = null;
        _lastShownBody = null;
        _lastShownSubText = null;
        await NotificationService().cancelOngoingService();
      }
      return;
    }
    await _showNotification(services.first);
  }

  // ── Build & show the ongoing notification ─────────────────────────────────
  Future<void> _showNotification(VehicleServiceModel latest) async {
    final odo = latest.odometer;
    final next = latest.nextServiceOdometer;
    final nextDate = latest.nextServiceDate;

    // Buat baris informasi
    final odoLine = 'Terakhir servis: $odo km';
    final nextLine = next != null
        ? 'Servis berikutnya: $next km'
        : nextDate != null
            ? 'Servis berikutnya: ${_formatDate(nextDate)}'
            : 'Jadwal servis belum diatur';

    final body = '$odoLine\n$nextLine';

    // Hitung sisa km
    String subText = 'Honda CB150R 2019';
    if (next != null && odo > 0) {
      final sisa = next - odo;
      if (sisa > 0) {
        subText = 'Sisa ±$sisa km sebelum servis';
      } else {
        subText = '⚠️ Sudah melewati jadwal servis!';
      }
    }

    final title = '🏍️ CB150R — ${latest.title}';

    // OPTIMASI: Cegah IPC notifikasi yang tidak perlu jika konten tidak berubah
    if (_lastShownWasOngoing &&
        _lastShownTitle == title &&
        _lastShownBody == body &&
        _lastShownSubText == subText) {
      return;
    }

    _lastShownTitle = title;
    _lastShownBody = body;
    _lastShownSubText = subText;
    _lastShownWasOngoing = true;

    await NotificationService().showOngoingServiceReminder(
      title: title,
      body: body,
      subText: subText,
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
