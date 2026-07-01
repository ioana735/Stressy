import '../models/planned_block.dart';
import '../models/study_session.dart';
import '../models/study_style.dart';
import 'stats_service.dart';

/// Calcule pure pentru planificare: progres pe materie, plan vs realizat,
/// generator automat de plan. Fara I/O.
class PlanService {
  /// Inceputul saptamanii (luni 00:00) care contine [d].
  static DateTime weekStart(DateTime d) {
    final day = StatsService.dayOnly(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static bool _sameSubject(String? a, String b) =>
      (a ?? '').trim().toLowerCase() == b.trim().toLowerCase();

  /// Minute studiate la o materie in saptamana curenta.
  static int weeklyMinutesForSubject(
      List<StudySession> sessions, String subject, DateTime now) {
    final start = weekStart(now);
    final end = start.add(const Duration(days: 7));
    return sessions
        .where((s) =>
            _sameSubject(s.subject, subject) &&
            !s.date.isBefore(start) &&
            s.date.isBefore(end))
        .fold(0, (sum, s) => sum + s.minutes);
  }

  /// Minute studiate la o materie intr-o anumita zi.
  static int minutesForSubjectOnDay(
      List<StudySession> sessions, String subject, DateTime day) {
    final d = StatsService.dayOnly(day);
    return sessions
        .where((s) =>
            _sameSubject(s.subject, subject) &&
            StatsService.dayOnly(s.date) == d)
        .fold(0, (sum, s) => sum + s.minutes);
  }

  /// Blocurile planificate pentru o zi.
  static List<PlannedBlock> blocksForDay(
      List<PlannedBlock> blocks, DateTime day) {
    final d = StatsService.dayOnly(day);
    return blocks.where((b) => StatsService.dayOnly(b.date) == d).toList();
  }

  /// Total minute planificate pe materie in saptamana lui [now].
  static int weeklyPlannedForSubject(
      List<PlannedBlock> blocks, String subject, DateTime now) {
    final start = weekStart(now);
    final end = start.add(const Duration(days: 7));
    return blocks
        .where((b) =>
            _sameSubject(b.subject, subject) &&
            !b.date.isBefore(start) &&
            b.date.isBefore(end))
        .fold(0, (sum, b) => sum + b.plannedMinutes);
  }

  /// Genereaza un plan: distribuie [totalMinutes] pentru [subject] pe zilele
  /// dintre [from] si [to] inclusiv, dupa [style] (uniform sau intensiv spre
  /// final). Intoarce o lista de blocuri noi.
  /// [idSeed] = baza pentru ID-uri unice (ex. microsecondsSinceEpoch).
  static List<PlannedBlock> generatePlan({
    required String subject,
    required int totalMinutes,
    required DateTime from,
    required DateTime to,
    required int idSeed,
    StudyStyle style = StudyStyle.spaced,
  }) {
    final start = StatsService.dayOnly(from);
    final end = StatsService.dayOnly(to);
    final days = end.difference(start).inDays + 1;
    if (days <= 0 || totalMinutes <= 0) return [];

    // greutati per zi, in functie de stil
    final weights = List.generate(days, (i) => style.weight(i, days));
    final sumW = weights.fold(0.0, (a, b) => a + b);

    // minute brute -> rotunjite la multiplu de 5 (min 5/zi)
    final raw = <int>[];
    for (var i = 0; i < days; i++) {
      var m = (totalMinutes * weights[i] / sumW);
      var r = (m / 5).round() * 5;
      if (r < 5) r = 5;
      raw.add(r);
    }

    // ajusteaza ultima zi ca suma sa fie exact totalMinutes
    var diff = totalMinutes - raw.fold(0, (a, b) => a + b);
    raw[days - 1] = (raw[days - 1] + diff).clamp(5, 100000).toInt();

    final result = <PlannedBlock>[];
    for (var i = 0; i < days; i++) {
      result.add(PlannedBlock(
        id: '${idSeed}_$i',
        date: start.add(Duration(days: i)),
        subject: subject,
        plannedMinutes: raw[i],
      ));
    }
    return result;
  }
}
