/// O sesiune de studiu inregistrata (data + durata).
class StudySession {
  final DateTime date;
  final int minutes;
  final String? subject; // optional: materia

  StudySession({required this.date, required this.minutes, this.subject});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minutes': minutes,
        if (subject != null) 'subject': subject,
      };

  factory StudySession.fromJson(Map<String, dynamic> j) => StudySession(
        date: DateTime.parse(j['date'] as String),
        minutes: (j['minutes'] as num).toInt(),
        subject: j['subject'] as String?,
      );
}
