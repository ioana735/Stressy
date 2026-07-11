/// O componenta de nota in cadrul unei materii (ex. Examen 60%, Seminar 40%).
class GradeComponent {
  final String name;
  final double grade;
  final int percent;

  const GradeComponent(
      {required this.name, required this.grade, required this.percent});

  Map<String, dynamic> toJson() =>
      {'name': name, 'grade': grade, 'percent': percent};

  factory GradeComponent.fromJson(Map<String, dynamic> j) => GradeComponent(
        name: j['name'] as String,
        grade: (j['grade'] as num).toDouble(),
        percent: (j['percent'] as num).toInt(),
      );
}

/// Nota la o materie, cu an/semestru, credite, si fie o nota directa, fie
/// componente (%) din care se calculeaza nota finala.
class SubjectGrade {
  final String id;
  final String subject;
  final int year; // anul (1, 2, 3...)
  final int semester; // 1 sau 2
  final int credits;
  final double? directGrade;
  final List<GradeComponent> components;

  /// Note simple (liceu): media aritmetica a acestor note.
  final List<double> simpleGrades;

  const SubjectGrade({
    required this.id,
    required this.subject,
    this.year = 1,
    this.semester = 1,
    this.credits = 0,
    this.directGrade,
    this.components = const [],
    this.simpleGrades = const [],
  });

  /// Nota finala:
  ///  - note simple -> media aritmetica
  ///  - componente -> medie ponderata pe %
  ///  - altfel -> nota directa
  double? get finalGrade {
    if (simpleGrades.isNotEmpty) {
      return simpleGrades.reduce((a, b) => a + b) / simpleGrades.length;
    }
    if (components.isNotEmpty) {
      final totalPct = components.fold(0, (s, c) => s + c.percent);
      if (totalPct == 0) return null;
      final weighted = components.fold(0.0, (s, c) => s + c.grade * c.percent);
      return weighted / totalPct;
    }
    return directGrade;
  }

  SubjectGrade copyWith({
    String? subject,
    int? year,
    int? semester,
    int? credits,
    double? directGrade,
    List<GradeComponent>? components,
    List<double>? simpleGrades,
  }) =>
      SubjectGrade(
        id: id,
        subject: subject ?? this.subject,
        year: year ?? this.year,
        semester: semester ?? this.semester,
        credits: credits ?? this.credits,
        directGrade: directGrade ?? this.directGrade,
        components: components ?? this.components,
        simpleGrades: simpleGrades ?? this.simpleGrades,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'year': year,
        'semester': semester,
        'credits': credits,
        'directGrade': directGrade,
        'components': components.map((c) => c.toJson()).toList(),
        'simpleGrades': simpleGrades,
      };

  factory SubjectGrade.fromJson(Map<String, dynamic> j) => SubjectGrade(
        id: j['id'] as String,
        subject: j['subject'] as String,
        year: (j['year'] as num?)?.toInt() ?? 1,
        semester: (j['semester'] as num?)?.toInt() ?? 1,
        credits: (j['credits'] as num?)?.toInt() ?? 0,
        directGrade: (j['directGrade'] as num?)?.toDouble(),
        components: ((j['components'] as List?) ?? [])
            .map((e) => GradeComponent.fromJson(e as Map<String, dynamic>))
            .toList(),
        simpleGrades: ((j['simpleGrades'] as List?) ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}
