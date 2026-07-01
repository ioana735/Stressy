import 'study_style.dart';

/// Un examen pus pe calendar, cu data si ora.
class Exam {
  final String id;
  final String name; // materia / numele examenului
  final DateTime dateTime; // data + ora examenului

  /// Optional: de cand sa primeasca notificari de studiu (doar data conteaza).
  final DateTime? notifyFrom;

  /// Optional: cate ore vrea sa studieze total pentru acest examen.
  /// Daca e setat, se genereaza automat un plan pana la examen.
  final int? studyHoursTarget;

  /// Stilul folosit pentru planul auto-generat.
  final StudyStyle studyStyle;

  const Exam({
    required this.id,
    required this.name,
    required this.dateTime,
    this.notifyFrom,
    this.studyHoursTarget,
    this.studyStyle = StudyStyle.spaced,
  });

  /// Cate zile mai sunt pana la examen (de azi).
  int daysUntil(DateTime now) {
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return d1.difference(d0).inDays;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dateTime': dateTime.toIso8601String(),
        'notifyFrom': notifyFrom?.toIso8601String(),
        'studyHoursTarget': studyHoursTarget,
        'studyStyle': studyStyle.index,
      };

  factory Exam.fromJson(Map<String, dynamic> j) => Exam(
        id: j['id'] as String,
        name: j['name'] as String,
        dateTime: DateTime.parse(j['dateTime'] as String),
        notifyFrom: j['notifyFrom'] == null
            ? null
            : DateTime.parse(j['notifyFrom'] as String),
        studyHoursTarget: (j['studyHoursTarget'] as num?)?.toInt(),
        studyStyle: StudyStyle.values[
            ((j['studyStyle'] as num?)?.toInt() ?? 0)
                .clamp(0, StudyStyle.values.length - 1)],
      );
}
