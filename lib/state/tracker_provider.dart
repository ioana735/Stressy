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
import '../models/subject_grade.dart';
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
  final List<SubjectGrade> grades;

  const TrackerState({
    required this.sessions,
    required this.settings,
    required this.streak,
    this.goals = const [],
    this.blocks = const [],
    this.exams = const [],
    this.grades = const [],
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
    List<SubjectGrade>? grades,
  }) =>
      TrackerState(
        sessions: sessions ?? this.sessions,
        settings: settings ?? this.settings,
        streak: streak ?? this.streak,
        goals: goals ?? this.goals,
        blocks: blocks ?? this.blocks,
        exams: exams ?? this.exams,
        grades: grades ?? this.grades,
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
      grades: s.loadGrades(),
    );
  }

  // --- Backup ---
  String exportData() => _storage.exportJson();

  Future<bool> importData(String raw) async {
    final ok = await _storage.importJson(raw);
    if (ok) {
      state = _initial(_storage);
      _syncNotifications();
    }
    return ok;
  }

  // --- Note ---
  Future<void> saveGrade(SubjectGrade g) async {
    final grades = [...state.grades];
    final i = grades.indexWhere((x) => x.id == g.id);
    if (i >= 0) {
      grades[i] = g;
    } else {
      grades.add(g);
    }
    await _storage.saveGrades(grades);
    state = state.copyWith(grades: grades);
  }

  Future<void> deleteGrade(SubjectGrade g) async {
    final grades = [...state.grades]..removeWhere((x) => x.id == g.id);
    await _storage.saveGrades(grades);
    state = state.copyWith(grades: grades);
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

  /// Sterge toate sesiunile de studiu la o materie, intr-o anumita zi
  /// (folosit pentru sesiunile "in afara planului" de pe Dashboard).
  Future<void> deleteSessionsForSubjectOnDay(String subject, DateTime day) async {
    final d = StatsService.dayOnly(day);
    final updated = state.sessions
        .where((s) =>
            !((s.subject ?? '').trim().toLowerCase() ==
                    subject.trim().toLowerCase() &&
                StatsService.dayOnly(s.date) == d))
        .toList();
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

    // Distribuie automat obiectivul pe zilele ramase din saptamana (task-uri
    // pe timp care se umplu singure cand studiezi materia).
    final blocks = _regenGoalBlocks(subject, weeklyMinutes);

    await _storage.saveGoals(goals);
    await _storage.saveBlocks(blocks);
    state = state.copyWith(goals: goals, blocks: blocks);
  }

  Future<void> deleteGoal(SubjectGoal g) async {
    final goals = [...state.goals]..remove(g);
    // scoate si task-urile auto generate din acest obiectiv (azi + viitor)
    final today = StatsService.dayOnly(DateTime.now());
    final blocks = state.blocks
        .where((b) => !(b.fromGoal &&
            b.subject.toLowerCase() == g.subject.toLowerCase() &&
            !StatsService.dayOnly(b.date).isBefore(today)))
        .toList();
    await _storage.saveGoals(goals);
    await _storage.saveBlocks(blocks);
    state = state.copyWith(goals: goals, blocks: blocks);
  }

  /// Reface blocurile auto pentru [subject]: le scoate pe cele vechi (azi/viitor)
  /// si genereaza altele noi pana la finalul saptamanii.
  List<PlannedBlock> _regenGoalBlocks(String subject, int weeklyMinutes) {
    final now = DateTime.now();
    final today = StatsService.dayOnly(now);
    final endOfWeek = PlanService.weekEnd(now);

    // pastreaza tot ce NU e auto-din-acest-obiectiv-azi/viitor
    final kept = state.blocks
        .where((b) => !(b.fromGoal &&
            b.subject.toLowerCase() == subject.toLowerCase() &&
            !StatsService.dayOnly(b.date).isBefore(today)))
        .toList();

    if (endOfWeek.isBefore(today)) return kept; // saptamana s-a terminat
    final generated = PlanService.generatePlan(
      subject: subject,
      totalMinutes: weeklyMinutes,
      from: today,
      to: endOfWeek,
      idSeed: DateTime.now().microsecondsSinceEpoch,
      fromGoal: true,
    );
    return [...kept, ...generated];
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
  /// Adauga un examen. Daca [Exam.hoursPerDay] e setat, genereaza automat
  /// cate un bloc/zi de la [Exam.notifyFrom] (sau azi) pana in ziua examenului.
  Future<void> addExam(Exam exam) async {
    final exams = [...state.exams, exam];
    final blocks = [...state.blocks, ..._examBlocks(exam)];
    final grades = _rebuildExamGrades(exams);
    await _storage.saveExams(exams);
    await _storage.saveBlocks(blocks);
    await _storage.saveGrades(grades);
    state = state.copyWith(exams: exams, blocks: blocks, grades: grades);
    _syncNotifications();
  }

  /// Editeaza un examen: inlocuieste datele + regenereaza blocurile + notele.
  Future<void> updateExam(Exam updated) async {
    final exams = [...state.exams];
    final i = exams.indexWhere((x) => x.id == updated.id);
    if (i < 0) return;
    exams[i] = updated;
    final kept =
        state.blocks.where((b) => b.examId != updated.id).toList();
    final blocks = [...kept, ..._examBlocks(updated)];
    final grades = _rebuildExamGrades(exams);
    await _storage.saveExams(exams);
    await _storage.saveBlocks(blocks);
    await _storage.saveGrades(grades);
    state = state.copyWith(exams: exams, blocks: blocks, grades: grades);
    _syncNotifications();
  }

  /// Reconstruieste notele din examene: grupeaza examenele pe materie.
  /// Materie goala => nota separata (grupata dupa numele examenului).
  ///
  /// Liceu: medie aritmetica simpla a notelor (procentul din examen e ignorat).
  /// Facultate: medie ponderata pe procentul fiecarui examen (componente).
  List<SubjectGrade> _rebuildExamGrades(List<Exam> exams) {
    // pastreaza notele adaugate manual (id-uri fara prefix 'exam_')
    final kept = state.grades.where((g) => !g.id.startsWith('exam_')).toList();
    final uni = state.settings.universityGrades;

    final groups = <String, List<Exam>>{};
    for (final e in exams) {
      final key =
          (e.subject.trim().isNotEmpty ? e.subject.trim() : e.name).toLowerCase();
      groups.putIfAbsent(key, () => []).add(e);
    }

    final examGrades = <SubjectGrade>[];
    for (final entry in groups.entries) {
      final list = entry.value;
      final first = list.first;
      final display =
          first.subject.trim().isNotEmpty ? first.subject.trim() : first.name;
      // creditele/anul/semestrul se preiau de la primul examen din grup care
      // le are setate, ca sa fie de-ajuns sa le pui o singura data pe grup.
      final withCredits = list.firstWhere((e) => e.credits > 0, orElse: () => first);
      final grades = [for (final e in list) if (e.grade != null) e.grade!];
      examGrades.add(SubjectGrade(
        id: 'exam_${entry.key}',
        subject: display,
        year: first.year,
        semester: first.semester,
        credits: uni ? withCredits.credits : 0,
        components: uni
            ? [
                for (final e in list)
                  if (e.grade != null)
                    GradeComponent(
                        name: e.name, grade: e.grade!, percent: e.weightPercent),
              ]
            : const [],
        simpleGrades: uni ? const [] : grades,
      ));
    }
    return [...kept, ...examGrades];
  }

  List<PlannedBlock> _examBlocks(Exam exam) {
    if (exam.hoursPerDay == null || exam.hoursPerDay! <= 0) return [];
    final from = exam.notifyFrom ?? DateTime.now();
    final to = exam.dateTime.subtract(const Duration(days: 1));
    final safeTo = to.isBefore(from) ? from : to;
    return PlanService.generateDailyPlan(
      subject: exam.name,
      minutesPerDay: exam.hoursPerDay! * 60,
      from: from,
      to: safeTo,
      idSeed: DateTime.now().microsecondsSinceEpoch,
      examId: exam.id,
      note: exam.planNote,
    );
  }

  Future<void> setExamResult(Exam e, ExamResult result) async {
    final exams = [...state.exams];
    final i = exams.indexWhere((x) => x.id == e.id);
    if (i < 0) return;
    exams[i] = e.copyWith(result: result);
    await _storage.saveExams(exams);
    state = state.copyWith(exams: exams);
  }

  Future<void> deleteExam(Exam e) async {
    final exams = [...state.exams]..removeWhere((x) => x.id == e.id);
    final blocks = state.blocks.where((b) => b.examId != e.id).toList();
    final grades = _rebuildExamGrades(exams);
    await _storage.saveExams(exams);
    await _storage.saveBlocks(blocks);
    await _storage.saveGrades(grades);
    state = state.copyWith(exams: exams, blocks: blocks, grades: grades);
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

  Future<void> testNotification() async {
    await _notifications.showNow(
        'Test reminder 🔔', 'Așa vor arăta mementourile.');
    await _notifications.scheduleTest(seconds: 10);
  }
}
