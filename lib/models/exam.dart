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
      );
}
