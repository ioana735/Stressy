import 'study_style.dart';

/// Setarile aplicatiei de tracking: obiectiv zilnic + preferinte remindere.
class TrackerSettings {
  /// Obiectiv zilnic de studiu, in minute.
  final int dailyGoalMinutes;

  /// Reminder la ora fixa (ex. 18:00). null => dezactivat.
  final int? reminderHour;
  final int? reminderMinute;

  /// Memento daca nu ai invatat azi (verificat la [inactivityHour]).
  final bool inactivityReminder;
  final int inactivityHour;

  /// Avertizare cand esti pe cale sa pierzi streak-ul.
  final bool streakWarning;

  /// Stilul de invatare preferat (default pentru planurile generate).
  final StudyStyle studyStyle;

  /// Mod intunecat.
  final bool darkMode;

  const TrackerSettings({
    this.dailyGoalMinutes = 120,
    this.reminderHour = 18,
    this.reminderMinute = 0,
    this.inactivityReminder = true,
    this.inactivityHour = 20,
    this.streakWarning = true,
    this.studyStyle = StudyStyle.spaced,
    this.darkMode = false,
  });

  bool get hasDailyReminder => reminderHour != null && reminderMinute != null;

  TrackerSettings copyWith({
    int? dailyGoalMinutes,
    int? reminderHour,
    int? reminderMinute,
    bool clearReminder = false,
    bool? inactivityReminder,
    int? inactivityHour,
    bool? streakWarning,
    StudyStyle? studyStyle,
    bool? darkMode,
  }) =>
      TrackerSettings(
        dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
        reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
        reminderMinute:
            clearReminder ? null : (reminderMinute ?? this.reminderMinute),
        inactivityReminder: inactivityReminder ?? this.inactivityReminder,
        inactivityHour: inactivityHour ?? this.inactivityHour,
        streakWarning: streakWarning ?? this.streakWarning,
        studyStyle: studyStyle ?? this.studyStyle,
        darkMode: darkMode ?? this.darkMode,
      );

  Map<String, dynamic> toJson() => {
        'dailyGoalMinutes': dailyGoalMinutes,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'inactivityReminder': inactivityReminder,
        'inactivityHour': inactivityHour,
        'streakWarning': streakWarning,
        'studyStyle': studyStyle.index,
        'darkMode': darkMode,
      };

  factory TrackerSettings.fromJson(Map<String, dynamic> j) => TrackerSettings(
        dailyGoalMinutes: (j['dailyGoalMinutes'] as num?)?.toInt() ?? 120,
        reminderHour: (j['reminderHour'] as num?)?.toInt(),
        reminderMinute: (j['reminderMinute'] as num?)?.toInt(),
        inactivityReminder: j['inactivityReminder'] as bool? ?? true,
        inactivityHour: (j['inactivityHour'] as num?)?.toInt() ?? 20,
        streakWarning: j['streakWarning'] as bool? ?? true,
        studyStyle: StudyStyle.values[
            ((j['studyStyle'] as num?)?.toInt() ?? 0)
                .clamp(0, StudyStyle.values.length - 1)],
        darkMode: j['darkMode'] as bool? ?? false,
      );
}
