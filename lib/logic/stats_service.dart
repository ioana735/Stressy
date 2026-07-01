import '../models/study_session.dart';

/// Calcule pure pe lista de sesiuni (azi, saptamana, total). Fara I/O.
class StatsService {
  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Minute studiate intr-o anumita zi.
  static int minutesOn(List<StudySession> sessions, DateTime day) {
    final d = dayOnly(day);
    return sessions
        .where((s) => dayOnly(s.date) == d)
        .fold(0, (sum, s) => sum + s.minutes);
  }

  static int minutesToday(List<StudySession> sessions, DateTime now) =>
      minutesOn(sessions, now);

  /// Minute pe ultimele 7 zile, de la cea mai veche la azi (pentru grafic).
  static List<int> last7Days(List<StudySession> sessions, DateTime now) {
    return List.generate(7, (i) {
      final day = dayOnly(now).subtract(Duration(days: 6 - i));
      return minutesOn(sessions, day);
    });
  }

  static int totalMinutes(List<StudySession> sessions) =>
      sessions.fold(0, (sum, s) => sum + s.minutes);

  /// Cate zile distincte cu studiu (pentru "zile active").
  static int activeDays(List<StudySession> sessions) =>
      sessions.map((s) => dayOnly(s.date)).toSet().length;

  static bool studiedToday(List<StudySession> sessions, DateTime now) =>
      minutesToday(sessions, now) > 0;
}
