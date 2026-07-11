import '../models/subject_grade.dart';

/// Calcule pure pentru medii. Fara I/O.
class GradesService {
  static List<double> _finals(List<SubjectGrade> gs) =>
      gs.map((g) => g.finalGrade).whereType<double>().toList();

  /// Media aritmetica a notelor finale.
  static double? arithmetic(List<SubjectGrade> gs) {
    final fs = _finals(gs);
    if (fs.isEmpty) return null;
    return fs.reduce((a, b) => a + b) / fs.length;
  }

  /// Media ponderata pe credite: Σ(nota×credite) / Σcredite.
  static double? creditWeighted(List<SubjectGrade> gs) {
    double num = 0;
    int den = 0;
    for (final g in gs) {
      final f = g.finalGrade;
      if (f != null && g.credits > 0) {
        num += f * g.credits;
        den += g.credits;
      }
    }
    return den == 0 ? null : num / den;
  }

  static int totalCredits(List<SubjectGrade> gs) =>
      gs.where((g) => g.finalGrade != null).fold(0, (s, g) => s + g.credits);

  /// Combinatiile distincte (an, semestru) prezente, sortate.
  static List<(int, int)> periods(List<SubjectGrade> gs) {
    final set = <(int, int)>{};
    for (final g in gs) {
      set.add((g.year, g.semester));
    }
    final list = set.toList()
      ..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    return list;
  }
}
