/// Un task de studiu planificat: o materie, o zi, si ce anume ai de facut.
///
/// Poate avea:
///  - o tinta cantitativa optionala (ex. 30 [unitLabel]="pagini") cu [doneUnits]
///  - timp estimat optional [plannedMinutes]
///  - o notita libera [note]
///  - bifare manuala [done]
class PlannedBlock {
  final String id;
  final DateTime date;
  final String subject;
  final String? note; // ce ai de facut / notite
  final int plannedMinutes; // optional (0 = fara timp estimat)
  final int? targetUnits; // ex. 30
  final String? unitLabel; // ex. "pagini"
  final int doneUnits; // cat ai facut din tinta
  final bool done; // bifare manuala
  final bool fromGoal; // generat automat dintr-un obiectiv saptamanal
  final String? examId; // legat de un examen (generat automat)

  const PlannedBlock({
    required this.id,
    required this.date,
    required this.subject,
    this.note,
    this.plannedMinutes = 0,
    this.targetUnits,
    this.unitLabel,
    this.doneUnits = 0,
    this.done = false,
    this.fromGoal = false,
    this.examId,
  });

  bool get hasTarget => targetUnits != null && targetUnits! > 0;

  /// Task complet: bifat manual SAU tinta cantitativa atinsa.
  bool get isComplete =>
      done || (hasTarget && doneUnits >= targetUnits!);

  double get progress {
    if (hasTarget) return (doneUnits / targetUnits!).clamp(0.0, 1.0);
    return done ? 1.0 : 0.0;
  }

  PlannedBlock copyWith({
    DateTime? date,
    String? subject,
    String? note,
    int? plannedMinutes,
    int? targetUnits,
    String? unitLabel,
    int? doneUnits,
    bool? done,
    bool? fromGoal,
    String? examId,
  }) =>
      PlannedBlock(
        id: id,
        date: date ?? this.date,
        subject: subject ?? this.subject,
        note: note ?? this.note,
        plannedMinutes: plannedMinutes ?? this.plannedMinutes,
        targetUnits: targetUnits ?? this.targetUnits,
        unitLabel: unitLabel ?? this.unitLabel,
        doneUnits: doneUnits ?? this.doneUnits,
        done: done ?? this.done,
        fromGoal: fromGoal ?? this.fromGoal,
        examId: examId ?? this.examId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'subject': subject,
        'note': note,
        'plannedMinutes': plannedMinutes,
        'targetUnits': targetUnits,
        'unitLabel': unitLabel,
        'doneUnits': doneUnits,
        'done': done,
        'fromGoal': fromGoal,
        'examId': examId,
      };

  factory PlannedBlock.fromJson(Map<String, dynamic> j) => PlannedBlock(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        subject: j['subject'] as String,
        note: j['note'] as String?,
        plannedMinutes: (j['plannedMinutes'] as num?)?.toInt() ?? 0,
        targetUnits: (j['targetUnits'] as num?)?.toInt(),
        unitLabel: j['unitLabel'] as String?,
        doneUnits: (j['doneUnits'] as num?)?.toInt() ?? 0,
        done: j['done'] as bool? ?? false,
        fromGoal: j['fromGoal'] as bool? ?? false,
        examId: j['examId'] as String?,
      );
}
