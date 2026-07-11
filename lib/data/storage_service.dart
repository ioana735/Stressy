import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam.dart';
import '../models/planned_block.dart';
import '../models/study_session.dart';
import '../models/subject_goal.dart';
import '../models/subject_grade.dart';
import '../models/tracker_settings.dart';

/// Persistenta locala (shared_preferences). Tot ce tine de salvare e izolat aici.
class StorageService {
  static const _kSessions = 'sessions';
  static const _kSettings = 'settings';
  static const _kStreak = 'streak';
  static const _kLastStudyDay = 'last_study_day';
  static const _kGoals = 'subject_goals';
  static const _kBlocks = 'planned_blocks';
  static const _kExams = 'exams';
  static const _kGrades = 'grades';

  static const _allKeys = [
    _kSessions, _kSettings, _kStreak, _kLastStudyDay,
    _kGoals, _kBlocks, _kExams, _kGrades,
  ];

  final SharedPreferences _prefs;
  StorageService(this._prefs);

  static Future<StorageService> create() async =>
      StorageService(await SharedPreferences.getInstance());

  // --- Backup (export / import) ---
  /// Serializeaza toate datele intr-un text (pentru backup).
  String exportJson() {
    final data = <String, dynamic>{};
    for (final k in _allKeys) {
      final v = _prefs.get(k);
      if (v != null) data[k] = v;
    }
    return jsonEncode({'app': 'stressy', 'version': 1, 'data': data});
  }

  /// Restaureaza datele dintr-un text de backup. Intoarce true la succes.
  Future<bool> importJson(String raw) async {
    try {
      final decoded = jsonDecode(raw.trim()) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      for (final k in _allKeys) {
        await _prefs.remove(k);
      }
      for (final e in data.entries) {
        final v = e.value;
        if (v is String) {
          await _prefs.setString(e.key, v);
        } else if (v is bool) {
          await _prefs.setBool(e.key, v);
        } else if (v is int) {
          await _prefs.setInt(e.key, v);
        } else if (v is double) {
          await _prefs.setDouble(e.key, v);
        } else if (v is num) {
          await _prefs.setDouble(e.key, v.toDouble());
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Sesiuni ---
  List<StudySession> loadSessions() {
    final raw = _prefs.getString(_kSessions);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => StudySession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSessions(List<StudySession> sessions) => _prefs.setString(
      _kSessions, jsonEncode(sessions.map((s) => s.toJson()).toList()));

  // --- Setari ---
  TrackerSettings loadSettings() {
    final raw = _prefs.getString(_kSettings);
    if (raw == null) return const TrackerSettings();
    try {
      return TrackerSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TrackerSettings();
    }
  }

  Future<void> saveSettings(TrackerSettings s) =>
      _prefs.setString(_kSettings, jsonEncode(s.toJson()));

  // --- Obiective pe materie ---
  List<SubjectGoal> loadGoals() {
    final raw = _prefs.getString(_kGoals);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => SubjectGoal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGoals(List<SubjectGoal> goals) => _prefs.setString(
      _kGoals, jsonEncode(goals.map((g) => g.toJson()).toList()));

  // --- Blocuri planificate ---
  List<PlannedBlock> loadBlocks() {
    final raw = _prefs.getString(_kBlocks);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PlannedBlock.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBlocks(List<PlannedBlock> blocks) => _prefs.setString(
      _kBlocks, jsonEncode(blocks.map((b) => b.toJson()).toList()));

  // --- Examene ---
  List<Exam> loadExams() {
    final raw = _prefs.getString(_kExams);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Exam.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExams(List<Exam> exams) => _prefs.setString(
      _kExams, jsonEncode(exams.map((e) => e.toJson()).toList()));

  // --- Note ---
  List<SubjectGrade> loadGrades() {
    final raw = _prefs.getString(_kGrades);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => SubjectGrade.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGrades(List<SubjectGrade> grades) => _prefs.setString(
      _kGrades, jsonEncode(grades.map((g) => g.toJson()).toList()));

  // --- Streak ---
  int get streak => _prefs.getInt(_kStreak) ?? 0;
  Future<void> setStreak(int v) => _prefs.setInt(_kStreak, v);

  DateTime? get lastStudyDay {
    final s = _prefs.getString(_kLastStudyDay);
    return s == null ? null : DateTime.tryParse(s);
  }

  Future<void> setLastStudyDay(DateTime d) =>
      _prefs.setString(_kLastStudyDay, d.toIso8601String());
}
