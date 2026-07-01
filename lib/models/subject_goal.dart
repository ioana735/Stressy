/// Obiectiv saptamanal de studiu pentru o materie (ex. Matematica 5h/sapt).
class SubjectGoal {
  final String subject;
  final int weeklyMinutes;

  const SubjectGoal({required this.subject, required this.weeklyMinutes});

  SubjectGoal copyWith({String? subject, int? weeklyMinutes}) => SubjectGoal(
        subject: subject ?? this.subject,
        weeklyMinutes: weeklyMinutes ?? this.weeklyMinutes,
      );

  Map<String, dynamic> toJson() =>
      {'subject': subject, 'weeklyMinutes': weeklyMinutes};

  factory SubjectGoal.fromJson(Map<String, dynamic> j) => SubjectGoal(
        subject: j['subject'] as String,
        weeklyMinutes: (j['weeklyMinutes'] as num).toInt(),
      );
}
