import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/exam.dart';
import '../models/tracker_settings.dart';

/// Notificari locale (fara backend). Programeaza reminderele de studiu.
///
/// IMPORTANT: notificarile locale NU functioneaza pe web (Chrome). Merg doar
/// pe Android / iOS. Pe web, metodele de aici sunt no-op ca sa nu crape app-ul.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // ID-uri fixe ca sa putem rescrie/anula reminderele.
  static const _idDaily = 100;
  static const _idInactivity = 101;
  static const _idStreak = 102;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'study_reminders',
      'Remindere de studiu',
      channelDescription: 'Notificari care iti amintesc sa inveti',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    if (kIsWeb) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios));

    // cere permisiuni (Android 13+ / iOS)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _ready = true;
  }

  /// (Re)programeaza toate reminderele pe baza setarilor.
  /// [studiedToday] / [streak] influenteaza mementourile conditionate.
  Future<void> reschedule(
    TrackerSettings s, {
    required bool studiedToday,
    required int streak,
    List<Exam> exams = const [],
  }) async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancelAll();
    await _scheduleExams(s, exams);

    if (s.hasDailyReminder) {
      await _scheduleDaily(
        _idDaily,
        s.reminderHour!,
        s.reminderMinute!,
        'Timpul de studiu! 📚',
        'Hai sa bifezi obiectivul de azi (${s.dailyGoalMinutes} min).',
      );
    }

    if (s.inactivityReminder && !studiedToday) {
      await _scheduleDaily(
        _idInactivity,
        s.inactivityHour,
        0,
        'Inca n-ai invatat azi 👀',
        'Mai e timp. Chiar si 15 minute conteaza!',
      );
    }

    if (s.streakWarning && streak > 0 && !studiedToday) {
      await _scheduleDaily(
        _idStreak,
        21,
        30,
        'Atentie la streak! 🔥',
        'Ai un streak de $streak zile. Nu-l rupe acum!',
      );
    }
  }

  /// Programeaza remindere zilnice pentru fiecare examen, de la [Exam.notifyFrom]
  /// pana in ziua examenului, la ora reminderului zilnic (sau 9:00).
  Future<void> _scheduleExams(TrackerSettings s, List<Exam> exams) async {
    final hour = s.reminderHour ?? 9;
    final minute = s.reminderMinute ?? 0;
    var id = 200; // ID-uri separate de reminderele generice
    final now = tz.TZDateTime.now(tz.local);

    for (final exam in exams) {
      final start = exam.notifyFrom ?? now;
      var day = tz.TZDateTime(
          tz.local, start.year, start.month, start.day, hour, minute);
      final examDay = tz.TZDateTime(tz.local, exam.dateTime.year,
          exam.dateTime.month, exam.dateTime.day, hour, minute);

      // maxim 45 de notificari per examen (siguranta)
      var count = 0;
      while (!day.isAfter(examDay) && count < 45 && id < 900) {
        if (day.isAfter(now)) {
          final daysLeft = examDay.difference(day).inDays;
          await _plugin.zonedSchedule(
            id++,
            'Studiază pentru ${exam.name} 📖',
            daysLeft == 0
                ? 'Azi e examenul! Mult succes! 🍀'
                : 'Mai sunt $daysLeft ${daysLeft == 1 ? "zi" : "zile"} până la examen.',
            day,
            _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          count++;
        }
        day = day.add(const Duration(days: 1));
      }
    }
  }

  Future<void> _scheduleDaily(
      int id, int hour, int minute, String title, String body) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // se repeta zilnic
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Notificare imediata (ex. test din ecranul de setari).
  Future<void> showNow(String title, String body) async {
    if (kIsWeb || !_ready) return;
    await _plugin.show(1, title, body, _details);
  }

  Future<void> cancelAll() async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancelAll();
  }
}
