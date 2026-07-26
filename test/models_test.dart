import 'package:flutter_test/flutter_test.dart';
import 'package:stressy/models/exam.dart';
import 'package:stressy/models/study_session.dart';
import 'package:stressy/models/study_style.dart';
import 'package:stressy/models/tracker_settings.dart';

void main() {
  group('Exam', () {
    final exam = Exam(
      id: 'e1',
      name: 'Analiză',
      dateTime: DateTime(2026, 8, 20, 9, 30),
      kind: ExamKind.examen,
      format: ExamFormat.scris,
      colorValue: 0xFF6366F1,
      credits: 6,
      grade: 8.5,
      subject: 'Matematică',
      weightPercent: 40,
    );

    test('toJson/fromJson pastreaza toate campurile', () {
      final copy = Exam.fromJson(exam.toJson());
      expect(copy.id, exam.id);
      expect(copy.name, exam.name);
      expect(copy.dateTime, exam.dateTime);
      expect(copy.kind, exam.kind);
      expect(copy.format, exam.format);
      expect(copy.colorValue, 0xFF6366F1);
      expect(copy.credits, 6);
      expect(copy.grade, 8.5);
      expect(copy.subject, 'Matematică');
      expect(copy.weightPercent, 40);
    });

    test('fromJson pe date incomplete foloseste default-uri sigure', () {
      final copy = Exam.fromJson({
        'id': 'x',
        'name': 'Fizică',
        'dateTime': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(copy.kind, ExamKind.examen);
      expect(copy.format, ExamFormat.scris);
      expect(copy.colorValue, 0xFFE5484D);
      expect(copy.year, 1);
      expect(copy.weightPercent, 100);
      expect(copy.grade, isNull);
    });

    test('copyWith clearGrade sterge nota', () {
      final cleared = exam.copyWith(clearGrade: true);
      expect(cleared.grade, isNull);
      // restul raman neschimbate
      expect(cleared.subject, 'Matematică');
    });

    test('copyWith fara clearGrade pastreaza nota', () {
      final same = exam.copyWith(name: 'Analiză II');
      expect(same.grade, 8.5);
      expect(same.name, 'Analiză II');
    });

    test('daysUntil ignora ora', () {
      final e = exam.copyWith(dateTime: DateTime(2026, 7, 28, 23, 59));
      expect(e.daysUntil(DateTime(2026, 7, 26, 1, 0)), 2);
      expect(e.daysUntil(DateTime(2026, 7, 28, 8, 0)), 0); // azi
      expect(e.daysUntil(DateTime(2026, 7, 29, 0, 0)), -1); // trecut
    });

    test('kindLabel foloseste customLabel doar la altele', () {
      final proj = exam.copyWith(kind: ExamKind.altele, customLabel: 'Proiect');
      expect(proj.kindLabel, 'Proiect');
      final testEx = exam.copyWith(kind: ExamKind.test, customLabel: 'ignorat');
      expect(testEx.kindLabel, 'Test');
    });
  });

  group('TrackerSettings', () {
    test('roundtrip JSON', () {
      const s = TrackerSettings(
        dailyGoalMinutes: 180,
        reminderTimes: [480, 1200],
        darkMode: true,
        universityGrades: true,
        studyStyle: StudyStyle.cramming,
      );
      final copy = TrackerSettings.fromJson(s.toJson());
      expect(copy.dailyGoalMinutes, 180);
      expect(copy.reminderTimes, [480, 1200]);
      expect(copy.darkMode, isTrue);
      expect(copy.universityGrades, isTrue);
      expect(copy.studyStyle, StudyStyle.cramming);
    });

    test('migreaza din formatul vechi reminderHour -> reminderTimes', () {
      final copy = TrackerSettings.fromJson({
        'dailyGoalMinutes': 120,
        'reminderHour': 20,
        'reminderMinute': 15,
      });
      expect(copy.reminderTimes, [20 * 60 + 15]); // 1215
      expect(copy.primaryHour, 20);
      expect(copy.primaryMinute, 15);
    });

    test('fara remindere salvate cade pe default 18:00', () {
      final copy = TrackerSettings.fromJson({'dailyGoalMinutes': 90});
      expect(copy.reminderTimes, [1080]);
      expect(copy.primaryHour, 18);
      expect(copy.primaryMinute, 0);
    });

    test('primaryHour/primaryMinute pe lista goala nu crapa', () {
      const s = TrackerSettings(reminderTimes: []);
      expect(s.primaryHour, 18);
      expect(s.primaryMinute, 0);
    });
  });

  group('StudySession', () {
    test('roundtrip cu si fara subject', () {
      final a = StudySession(
          date: DateTime(2026, 7, 26, 10), minutes: 45, subject: 'Chimie');
      final ac = StudySession.fromJson(a.toJson());
      expect(ac.minutes, 45);
      expect(ac.subject, 'Chimie');
      expect(ac.date, a.date);

      final b = StudySession(date: DateTime(2026, 7, 26), minutes: 30);
      final bc = StudySession.fromJson(b.toJson());
      expect(bc.subject, isNull);
      expect(bc.minutes, 30);
    });
  });
}
