import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ReminderNotificationService {
  ReminderNotificationService._();

  static final ReminderNotificationService instance = ReminderNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'wedding_reminders';
  static const _channelName = 'Wedding reminders';
  static const _channelDesc = 'Alerts for dress fittings, hair, makeup, and other wedding appointments';

  Future<void> init() async {
    if (_ready || kIsWeb) return;

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Africa/Accra'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
            ),
          );
    }

    _ready = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await init();

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      return granted ?? true;
    }

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    return true;
  }

  Future<void> syncReminders(List<Map<String, dynamic>> reminders) async {
    if (kIsWeb) return;
    await init();
    await requestPermissions();
    await _plugin.cancelAll();

    for (final reminder in reminders) {
      final id = reminder['id'];
      if (id is! int) continue;

      if (reminder['is_done'] == true) {
        continue;
      }

      final when = DateTime.tryParse(reminder['remind_at']?.toString() ?? '');
      if (when == null) continue;

      await schedule(
        id: id,
        title: reminder['title']?.toString() ?? 'Wedding reminder',
        notes: reminder['notes']?.toString(),
        category: reminder['category']?.toString(),
        remindAt: when.toLocal(),
      );
    }
  }

  Future<void> schedule({
    required int id,
    required String title,
    required DateTime remindAt,
    String? notes,
    String? category,
  }) async {
    if (kIsWeb) return;
    await init();

    final when = remindAt.toLocal();
    if (!when.isAfter(DateTime.now().add(const Duration(seconds: 30)))) {
      await cancel(id);
      return;
    }

    final label = _categoryLabel(category);
    final timeLabel = DateFormat('EEE, MMM d · h:mm a').format(when);
    final body = [
      if (label != null) label,
      timeLabel,
      if (notes != null && notes.trim().isNotEmpty) notes.trim(),
    ].join('\n');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final scheduled = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
      payload: 'reminder:$id',
    );

    // Extra heads-up 1 hour before when the appointment is farther out.
    final hourBefore = when.subtract(const Duration(hours: 1));
    if (hourBefore.isAfter(DateTime.now().add(const Duration(minutes: 2)))) {
      await _plugin.zonedSchedule(
        id: _hourBeforeId(id),
        scheduledDate: tz.TZDateTime.from(hourBefore, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: 'Coming up: $title',
        body: 'In 1 hour · $timeLabel',
        payload: 'reminder:$id:soon',
      );
    } else {
      await cancel(_hourBeforeId(id));
    }
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(id: id);
    await _plugin.cancel(id: _hourBeforeId(id));
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancelAll();
  }

  int _hourBeforeId(int id) => 100000 + id;

  String? _categoryLabel(String? key) {
    switch (key) {
      case 'fitting':
        return 'Dress fitting';
      case 'hair':
        return 'Hairstylist';
      case 'makeup':
        return 'Makeup';
      case 'venue':
        return 'Venue';
      case 'vendor':
        return 'Vendor';
      case 'other':
        return 'Wedding prep';
      default:
        return key;
    }
  }
}
