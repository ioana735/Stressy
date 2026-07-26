import 'study_style.dart';

/// Setarile aplicatiei: obiectiv zilnic + ore de reminder alese de user.
class TrackerSettings {
  /// Obiectiv zilnic de studiu, in minute.
  final int dailyGoalMinutes;

  /// Orele la care vin notificarile de reminder (minute din zi, ex. 1080=18:00).
  final List<int> reminderTimes;

  /// Avertizare cand esti pe cale sa pierzi streak-ul.
  final bool streakWarning;

  /// Stilul de invatare preferat (default pentru planurile generate).
  final StudyStyle studyStyle;

  /// Mod intunecat.
  final bool darkMode;

  /// Mod note: false = liceu (medie aritmetica), true = facultate (credite).
  final bool universityGrades;

  const TrackerSettings({
    this.dailyGoalMinutes = 120,
    this.reminderTimes = const [1080], // 18:00
    this.streakWarning = true,
    this.studyStyle = StudyStyle.spaced,
    this.darkMode = false,
    this.universityGrades = false,
  });

  /// Ora principala (pentru remindere de examen / calendar).
  int get primaryHour =>
      reminderTimes.isEmpty ? 18 : reminderTimes.first ~/ 60;
  int get primaryMinute =>
      reminderTimes.isEmpty ? 0 : reminderTimes.first % 60;

  TrackerSettings copyWith({
    int? dailyGoalMinutes,
    List<int>? reminderTimes,
    bool? streakWarning,
    StudyStyle? studyStyle,
    bool? darkMode,
    bool? universityGrades,
  }) =>
      TrackerSettings(
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        reminderTimes: reminderTimes ?? this.reminderTimes,
        streakWarning: streakWarning ?? this.streakWarning,
        studyStyle: studyStyle ?? this.studyStyle,
        darkMode: darkMode ?? this.darkMode,
        universityGrades: universityGrades ?? this.universityGrades,
      );

  Map<String, dynamic> toJson() => {
        'dailyGoalMinutes': dailyGoalMinutes,
        'reminderTimes': reminderTimes,
        'streakWarning': streakWarning,
        'studyStyle': studyStyle.index,
        'darkMode': darkMode,
        'universityGrades': universityGrades,
      };

  factory TrackerSettings.fromJson(Map<String, dynamic> j) {
    // migrare din formatul vechi (reminderHour) daca e cazul
    List<int> times;
    final raw = j['reminderTimes'] as List?;
    if (raw != null) {
      times = raw.map((e) => (e as num).toInt()).toList();
    } else if (j['reminderHour'] != null) {
      final h = (j['reminderHour'] as num).toInt();
      final m = (j['reminderMinute'] as num?)?.toInt() ?? 0;
      times = [h * 60 + m];
    } else {
      times = const [1080];
    }
    return TrackerSettings(
      dailyGoalMinutes: (j['dailyGoalMinutes'] as num?)?.toInt() ?? 120,
      reminderTimes: times,
      streakWarning: j['streakWarning'] as bool? ?? true,
      studyStyle: StudyStyle.values[((j['studyStyle'] as num?)?.toInt() ?? 0)
          .clamp(0, StudyStyle.values.length - 1)],
      darkMode: j['darkMode'] as bool? ?? false,
      universityGrades: j['universityGrades'] as bool? ?? false,
    );
  }
}
