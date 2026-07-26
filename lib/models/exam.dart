import 'study_style.dart';

/// Rezultatul unui examen.
enum ExamResult { pending, passed, failed }

/// Tipul evenimentului.
enum ExamKind { examen, test, altele }

/// Forma examenului.
enum ExamFormat { scris, oral, none }

extension ExamKindX on ExamKind {
  String get label => switch (this) {
        ExamKind.examen => 'Examen',
        ExamKind.test => 'Test',
        ExamKind.altele => 'Altele',
      };
}

extension ExamFormatX on ExamFormat {
  String get label => switch (this) {
        ExamFormat.scris => 'Scris',
        ExamFormat.oral => 'Oral',
        ExamFormat.none => '—',
      };
}

/// Paleta de culori pentru examene (ARGB int).
const kExamColors = <int>[
  0xFFE5484D, // rosu
  0xFF6366F1, // indigo
  0xFF7C3AED, // violet
  0xFF22B07D, // verde
  0xFFF2A93B, // portocaliu
  0xFF0EA5E9, // albastru
  0xFFEC4899, // roz
  0xFF14B8A6, // teal
];

/// Un examen/eveniment pus pe calendar, cu data si ora.
class Exam {
  final String id;
  final String name; // materia / numele
  final DateTime dateTime; // data + ora
  final ExamKind kind;
  final ExamFormat format;

  /// Text liber cand [kind] == altele.
  final String? customLabel;

  /// De cand sa primeasca notificari / sa inceapa planul.
  final DateTime? notifyFrom;

  /// Cate ore pe zi vrea sa studieze (daca e setat, se genereaza plan zilnic).
  final int? hoursPerDay;

  final StudyStyle studyStyle;
  final ExamResult result;

  /// Culoarea examenului pe calendar (ARGB int).
  final int colorValue;

  // --- pentru sincronizarea cu sectiunea Note ---
  final int year;
  final int semester;
  final int credits;
  final double? grade; // nota obtinuta (null = inca nesustinut)

  /// Materia (cursul). Daca e gol, examenul e o nota de sine statatoare.
  /// Mai multe examene cu aceeasi materie se combina intr-o nota ponderata.
  final String subject;

  /// Cat conteaza acest examen in nota materiei (%).
  final int weightPercent;

  /// Ce ai de facut in fiecare zi din planul auto-generat (ex. "Cap. 3-5, exerciții").
  final String? planNote;

  const Exam({
    required this.id,
    required this.name,
    required this.dateTime,
    this.kind = ExamKind.examen,
    this.format = ExamFormat.scris,
    this.customLabel,
    this.notifyFrom,
    this.hoursPerDay,
    this.studyStyle = StudyStyle.spaced,
    this.result = ExamResult.pending,
    this.colorValue = 0xFFE5484D,
    this.year = 1,
    this.semester = 1,
    this.credits = 0,
    this.grade,
    this.subject = '',
    this.weightPercent = 100,
    this.planNote,
  });

  /// Eticheta de tip pentru afisare (foloseste customLabel la "altele").
  String get kindLabel =>
      kind == ExamKind.altele && (customLabel?.isNotEmpty ?? false)
          ? customLabel!
          : kind.label;

  int daysUntil(DateTime now) {
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return d1.difference(d0).inDays;
  }

  Exam copyWith({
    String? name,
    DateTime? dateTime,
    ExamKind? kind,
    ExamFormat? format,
    String? customLabel,
    DateTime? notifyFrom,
    int? hoursPerDay,
    StudyStyle? studyStyle,
    ExamResult? result,
    int? colorValue,
    int? year,
    int? semester,
    int? credits,
    double? grade,
    bool clearGrade = false,
    String? subject,
    int? weightPercent,
    String? planNote,
    bool clearPlanNote = false,
  }) =>
      Exam(
        id: id,
        name: name ?? this.name,
        dateTime: dateTime ?? this.dateTime,
        kind: kind ?? this.kind,
        format: format ?? this.format,
        customLabel: customLabel ?? this.customLabel,
        notifyFrom: notifyFrom ?? this.notifyFrom,
        hoursPerDay: hoursPerDay ?? this.hoursPerDay,
        studyStyle: studyStyle ?? this.studyStyle,
        result: result ?? this.result,
        colorValue: colorValue ?? this.colorValue,
        year: year ?? this.year,
        semester: semester ?? this.semester,
        credits: credits ?? this.credits,
        grade: clearGrade ? null : (grade ?? this.grade),
        subject: subject ?? this.subject,
        weightPercent: weightPercent ?? this.weightPercent,
        planNote: clearPlanNote ? null : (planNote ?? this.planNote),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dateTime': dateTime.toIso8601String(),
        'kind': kind.index,
        'format': format.index,
        'customLabel': customLabel,
        'notifyFrom': notifyFrom?.toIso8601String(),
        'hoursPerDay': hoursPerDay,
        'studyStyle': studyStyle.index,
        'result': result.index,
        'colorValue': colorValue,
        'year': year,
        'semester': semester,
        'credits': credits,
        'grade': grade,
        'subject': subject,
        'weightPercent': weightPercent,
        'planNote': planNote,
      };

  factory Exam.fromJson(Map<String, dynamic> j) => Exam(
        id: j['id'] as String,
        name: j['name'] as String,
        dateTime: DateTime.parse(j['dateTime'] as String),
        kind: ExamKind.values[((j['kind'] as num?)?.toInt() ?? 0)
            .clamp(0, ExamKind.values.length - 1)],
        format: ExamFormat.values[((j['format'] as num?)?.toInt() ?? 0)
            .clamp(0, ExamFormat.values.length - 1)],
        customLabel: j['customLabel'] as String?,
        notifyFrom: j['notifyFrom'] == null
            ? null
            : DateTime.parse(j['notifyFrom'] as String),
        hoursPerDay: (j['hoursPerDay'] as num?)?.toInt(),
        studyStyle: StudyStyle.values[((j['studyStyle'] as num?)?.toInt() ?? 0)
            .clamp(0, StudyStyle.values.length - 1)],
        result: ExamResult.values[((j['result'] as num?)?.toInt() ?? 0)
            .clamp(0, ExamResult.values.length - 1)],
        colorValue: (j['colorValue'] as num?)?.toInt() ?? 0xFFE5484D,
        year: (j['year'] as num?)?.toInt() ?? 1,
        semester: (j['semester'] as num?)?.toInt() ?? 1,
        credits: (j['credits'] as num?)?.toInt() ?? 0,
        grade: (j['grade'] as num?)?.toDouble(),
        subject: j['subject'] as String? ?? '',
        weightPercent: (j['weightPercent'] as num?)?.toInt() ?? 100,
        planNote: j['planNote'] as String?,
      );
}
