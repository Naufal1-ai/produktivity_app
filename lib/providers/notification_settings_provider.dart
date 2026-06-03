import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:productivity/data/models/vehicle_service_model.dart';
import 'package:productivity/data/models/task_model.dart';
import 'package:productivity/services/notification_service.dart';

/// Provider untuk mengatur state notifikasi persisten servis kendaraan.
/// Persists the toggle state across app restarts using SharedPreferences.
class NotificationSettingsProvider extends ChangeNotifier {
  static const String _prefKeyServiceReminder = 'pref_service_reminder_enabled';
  static const String _prefKeyTaskReminder = 'pref_task_reminder_enabled';

  bool _serviceReminderEnabled = false;
  bool _taskReminderEnabled = false;
  bool _permissionGranted = false;

  // Cache to prevent redundant notification IPC calls
  String? _lastShownTitle;
  String? _lastShownBody;
  String? _lastShownSubText;
  bool _lastShownWasOngoing = false;

  // Cache for task notifications to prevent redundant updates
  String? _lastTaskTitle;
  String? _lastTaskBody;
  String? _lastTaskSubText;
  bool _lastTaskWasOngoing = false;

  bool get serviceReminderEnabled => _serviceReminderEnabled;
  bool get taskReminderEnabled => _taskReminderEnabled;
  bool get permissionGranted => _permissionGranted;

  NotificationSettingsProvider() {
    _loadPrefs();
  }

  // ── Load saved preference ─────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _serviceReminderEnabled =
        prefs.getBool(_prefKeyServiceReminder) ?? false;
    _taskReminderEnabled =
        prefs.getBool(_prefKeyTaskReminder) ?? false;
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

  // ── Toggle task reminder ON/OFF ───────────────────────────────────────────
  Future<void> setTaskReminder({
    required bool enabled,
    List<TaskModel>? tasks,
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

    _taskReminderEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyTaskReminder, enabled);

    if (enabled && tasks != null) {
      await _showTaskNotification(tasks);
    } else {
      _lastTaskWasOngoing = false;
      _lastTaskTitle = null;
      _lastTaskBody = null;
      _lastTaskSubText = null;
      await NotificationService().cancelOngoingTask();
    }

    notifyListeners();
  }

  // ── Update notifikasi saat data task berubah ──────────────────────────────
  Future<void> updateTaskReminder(List<TaskModel> tasks) async {
    if (!_taskReminderEnabled) return;
    await _showTaskNotification(tasks);
  }

  // ── Build & show the ongoing task notification ────────────────────────────
  Future<void> _showTaskNotification(List<TaskModel> tasks) async {
    // Hanya ambil tugas yang belum selesai
    final activeTasks = tasks.where((t) => !t.completed).toList();

    if (activeTasks.isEmpty) {
      const title = '📋 Task & Jadwal';
      const body = 'Semua tugas telah selesai! 🎉';
      const subText = 'Bagus sekali!';

      if (_lastTaskWasOngoing &&
          _lastTaskTitle == title &&
          _lastTaskBody == body &&
          _lastTaskSubText == subText) {
        return;
      }

      _lastTaskTitle = title;
      _lastTaskBody = body;
      _lastTaskSubText = subText;
      _lastTaskWasOngoing = true;

      await NotificationService().showOngoingTaskReminder(
        title: title,
        body: body,
        subText: subText,
      );
      return;
    }

    // Sort by priority (High -> Medium -> Low) then by due date
    final sortedTasks = [...activeTasks];
    const priorityMap = {'High': 3, 'Medium': 2, 'Low': 1};
    sortedTasks.sort((a, b) {
      final pA = priorityMap[a.priority] ?? 2;
      final pB = priorityMap[b.priority] ?? 2;
      if (pA != pB) return pB.compareTo(pA); // High first
      return a.dueDate.compareTo(b.dueDate); // earliest due date first
    });

    // Build the summary body
    final buffer = StringBuffer();
    const displayLimit = 4;
    for (var i = 0; i < sortedTasks.length && i < displayLimit; i++) {
      final task = sortedTasks[i];
      final priorityEmoji = task.priority == 'High'
          ? '🔴'
          : task.priority == 'Medium'
              ? '🟡'
              : '🟢';
      buffer.writeln('${i + 1}. $priorityEmoji ${task.title}');
    }

    if (sortedTasks.length > displayLimit) {
      buffer.write('...dan ${sortedTasks.length - displayLimit} tugas lainnya');
    }

    final title = '📋 ${activeTasks.length} Tugas Aktif';
    final body = buffer.toString().trim();
    const subText = 'Kunci di bar notifikasi';

    if (_lastTaskWasOngoing &&
        _lastTaskTitle == title &&
        _lastTaskBody == body &&
        _lastTaskSubText == subText) {
      return;
    }

    _lastTaskTitle = title;
    _lastTaskBody = body;
    _lastTaskSubText = subText;
    _lastTaskWasOngoing = true;

    await NotificationService().showOngoingTaskReminder(
      title: title,
      body: body,
      subText: subText,
    );
  }
}
