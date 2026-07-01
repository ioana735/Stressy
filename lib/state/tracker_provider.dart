import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_service.dart';
import '../data/storage_service.dart';
import '../logic/plan_service.dart';
import '../logic/stats_service.dart';
import '../logic/streak_service.dart';
import '../models/exam.dart';
import '../models/planned_block.dart';
import '../models/study_session.dart';
import '../models/subject_goal.dart';
import '../models/tracker_settings.dart';

/// Injectate in main() dupa init.
final storageProvider = Provider<StorageService>(
    (ref) => throw UnimplementedError('override in main'));
final notificationProvider = Provider<NotificationService>(
    (ref) => throw UnimplementedError('override in main'));

final trackerControllerProvider =
    StateNotifierProvider<TrackerController, TrackerState>((ref) {
  return TrackerController(
    ref.watch(storageProvider),
    ref.watch(notificationProvider),
  );
});

@immutable
class TrackerState {
  final List<StudySession> sessions;
  final TrackerSettings settings;
  final int streak;
  final List<SubjectGoal> goals;
  final List<PlannedBlock> blocks;
  final List<Exam> exams;

  const TrackerState({
    required this.sessions,
    required this.settings,
    required this.streak,
    this.goals = const [],
    this.blocks = const [],
    this.exams = const [],
  });

  int get minutesToday => StatsService.minutesToday(sessions, DateTime.now());
  int get goal => settings.dailyGoalMinutes;
  double get goalProgress => goal == 0 ? 0 : (minutesToday / goal).clamp(0, 1);
  bool get goalReached => minutesToday >= goal;
  bool get studiedToday => minutesToday > 0;
  int get totalMinutes => StatsService.totalMinutes(sessions);
  int get activeDays => StatsService.activeDays(sessions);
  List<int> get last7Days => StatsService.last7Days(sessions, DateTime.now());

  TrackerState copyWith({
    List<StudySession>? sessions,
    TrackerSettings? settings,
    int? streak,
    List<SubjectGoal>? goals,
    List<PlannedBlock>? blocks,
    List<Exam>? exams,
  }) =>
      TrackerState(
        sessions: sessions ?? this.sessions,
        settings: settings ?? this.settings,
        streak: streak ?? this.streak,
        goals: goals ?? this.goals,
        blocks: blocks ?? this.blocks,
        exams: exams ?? this.exams,
      );
}

class TrackerController extends StateNotifier<TrackerState> {
  final StorageService _storage;
  final NotificationService _notifications;

  TrackerController(this._storage, this._notifications)
      : super(_initial(_storage)) {
    _syncNotifications();
  }

  static TrackerState _initial(StorageService s) {
    final now = DateTime.now();
    return TrackerState(
      sessions: s.loadSessions(),
      settings: s.loadSettings(),
      streak: StreakService.currentValidStreak(
        storedStreak: s.streak,
        lastStudyDay: s.lastStudyDay,
        now: now,
      ),
      goals: s.loadGoals(),
      blocks: s.loadBlocks(),
      exams: s.loadExams(),
    );
  }

  /// Inregistreaza o sesiune de studiu (din timer sau adaugata manual).
  Future<void> logSession(int minutes, {String? subject, DateTime? when}) async {
    final now = when ?? DateTime.now();
    final session = StudySession(date: now, minutes: minutes, subject: subject);
    final updated = [...state.sessions, session];

    final streakRes = StreakService.registerStudy(
      currentStreak: state.streak,
      lastStudyDay: _storage.lastStudyDay,
      now: now,
    );

    await _storage.saveSessions(updated);
    await _storage.setStreak(streakRes.streak);
    await _storage.setLastStudyDay(streakRes.lastStudyDay);

    state = state.copyWith(sessions: updated, streak: streakRes.streak);
    _syncNotifications();
  }

  Future<void> updateSettings(TrackerSettings s) async {
    await _storage.saveSettings(s);
    state = state.copyWith(settings: s);
    _syncNotifications();
  }

  Future<void> deleteSession(StudySession s) async {
    final updated = [...state.sessions]..remove(s);
    await _storage.saveSessions(updated);
    state = state.copyWith(sessions: updated);
    _syncNotifications();
  }

  // --- Obiective pe materie ---
  Future<void> setGoal(String subject, int weeklyMinutes) async {
    final goals = [...state.goals];
    final i = goals.indexWhere(
        (g) => g.subject.toLowerCase() == subject.toLowerCase());
    final goal = SubjectGoal(subject: subject, weeklyMinutes: weeklyMinutes);
    if (i >= 0) {
      goals[i] = goal;
    } else {
      goals.add(goal);
    }
    await _storage.saveGoals(goals);
    state = state.copyWith(goals: goals);
  }

  Future<void> deleteGoal(SubjectGoal g) async {
    final goals = [...state.goals]..remove(g);
    await _storage.saveGoals(goals);
    state = state.copyWith(goals: goals);
  }

  // --- Blocuri planificate ---
  Future<void> addBlock(PlannedBlock b) async {
    final blocks = [...state.blocks, b];
    await _storage.saveBlocks(blocks);
    state = state.copyWith(blocks: blocks);
  }

  Future<void> addBlocks(List<PlannedBlock> newBlocks) async {
    final blocks = [...state.blocks, ...newBlocks];
    await _storage.saveBlocks(blocks);
    state = state.copyWith(blocks: blocks);
  }

  Future<void> deleteBlock(PlannedBlock b) async {
    final blocks = [...state.blocks]..removeWhere((x) => x.id == b.id);
    await _storage.saveBlocks(blocks);
    state = state.copyWith(blocks: blocks);
  }

  Future<void> updateBlock(PlannedBlock updated) async {
    final blocks = [...state.blocks];
    final i = blocks.indexWhere((x) => x.id == updated.id);
    if (i < 0) return;
    blocks[i] = updated;
    await _storage.saveBlocks(blocks);
    state = state.copyWith(blocks: blocks);
  }

  void toggleBlockDone(PlannedBlock b) => updateBlock(b.copyWith(done: !b.done));

  void changeBlockUnits(PlannedBlock b, int delta) {
    final max = b.targetUnits ?? 100000;
    final v = (b.doneUnits + delta).clamp(0, max);
    updateBlock(b.copyWith(doneUnits: v));
  }

  // --- Examene ---
  /// Adauga un examen. Daca [Exam.studyHoursTarget] e setat, genereaza automat
  /// un plan de studiu de la [Exam.notifyFrom] (sau azi) pana in ziua examenului.
  Future<void> addExam(Exam exam) async {
    final exams = [...state.exams, exam];
    var blocks = state.blocks;

    if (exam.studyHoursTarget != null && exam.studyHoursTarget! > 0) {
      final from = exam.notifyFrom ?? DateTime.now();
      final to = exam.dateTime.subtract(const Duration(days: 1));
      final generated = PlanService.generatePlan(
        subject: exam.name,
        totalMinutes: exam.studyHoursTarget! * 60,
        from: from,
        to: to.isBefore(from) ? from : to,
        idSeed: DateTime.now().microsecondsSinceEpoch,
        style: exam.studyStyle,
      );
      blocks = [...state.blocks, ...generated];
      await _storage.saveBlocks(blocks);
    }

    await _storage.saveExams(exams);
    state = state.copyWith(exams: exams, blocks: blocks);
    _syncNotifications();
  }

  Future<void> deleteExam(Exam e) async {
    final exams = [...state.exams]..removeWhere((x) => x.id == e.id);
    await _storage.saveExams(exams);
    state = state.copyWith(exams: exams);
    _syncNotifications();
  }

  void _syncNotifications() {
    _notifications.reschedule(
      state.settings,
      studiedToday: state.studiedToday,
      streak: state.streak,
      exams: state.exams,
    );
  }

  Future<void> testNotification() =>
      _notifications.showNow('Test reminder 🔔', 'Asa vor arata mementourile.');
}
