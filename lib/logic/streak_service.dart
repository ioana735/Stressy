/// Calcul pur de streak-uri zilnice. Fara dependinte de I/O.
class StreakResult {
  final int streak;
  final DateTime lastStudyDay;
  const StreakResult(this.streak, this.lastStudyDay);
}

class StreakService {
  /// Recalculeaza streak-ul cand userul termina o sesiune azi.
  ///
  /// - aceeasi zi  -> streak neschimbat
  /// - ziua urmatoare -> streak + 1
  /// - gap > 1 zi  -> streak resetat la 1
  static StreakResult registerStudy({
    required int currentStreak,
    required DateTime? lastStudyDay,
    required DateTime now,
  }) {
    final today = _dayOnly(now);
    if (lastStudyDay == null) {
      return StreakResult(1, today);
    }
    final last = _dayOnly(lastStudyDay);
    final diff = today.difference(last).inDays;
    if (diff == 0) return StreakResult(currentStreak, today);
    if (diff == 1) return StreakResult(currentStreak + 1, today);
    return StreakResult(1, today);
  }

  /// Verifica daca streak-ul a fost rupt (la deschiderea app-ului).
  static int currentValidStreak({
    required int storedStreak,
    required DateTime? lastStudyDay,
    required DateTime now,
  }) {
    if (lastStudyDay == null) return 0;
    final diff = _dayOnly(now).difference(_dayOnly(lastStudyDay)).inDays;
    return diff <= 1 ? storedStreak : 0;
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
