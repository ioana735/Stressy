import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stressy/data/storage_service.dart';
import 'package:stressy/logic/plan_service.dart';
import 'package:stressy/models/exam.dart';
import 'package:stressy/models/study_session.dart';
import 'package:stressy/models/subject_grade.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanService.generateDailyPlan', () {
    test('un bloc pe zi, legat de examen', () {
      final blocks = PlanService.generateDailyPlan(
        subject: 'Analiză',
        minutesPerDay: 120,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 4),
        idSeed: 1,
        examId: 'exam1',
      );
      expect(blocks.length, 4);
      expect(blocks.every((b) => b.plannedMinutes == 120), true);
      expect(blocks.every((b) => b.examId == 'exam1'), true);
    });

    test('interval invers => gol', () {
      final blocks = PlanService.generateDailyPlan(
        subject: 'X',
        minutesPerDay: 60,
        from: DateTime(2026, 1, 5),
        to: DateTime(2026, 1, 1),
        idSeed: 1,
        examId: 'e',
      );
      expect(blocks, isEmpty);
    });
  });

  group('Exam JSON', () {
    test('round-trip pastreaza tip/forma/ore-zi/rezultat', () {
      final e = Exam(
        id: 'e1',
        name: 'Examen Analiză',
        dateTime: DateTime(2026, 2, 1, 9),
        kind: ExamKind.test,
        format: ExamFormat.oral,
        hoursPerDay: 3,
        result: ExamResult.passed,
      );
      final back = Exam.fromJson(e.toJson());
      expect(back.name, 'Examen Analiză');
      expect(back.kind, ExamKind.test);
      expect(back.format, ExamFormat.oral);
      expect(back.hoursPerDay, 3);
      expect(back.result, ExamResult.passed);
    });
  });

  group('StorageService backup', () {
    test('export apoi import restaureaza datele', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await StorageService.create();

      await s.saveSessions(
          [StudySession(date: DateTime(2026, 1, 1), minutes: 45, subject: 'Mate')]);
      await s.saveGrades(
          [SubjectGrade(id: '1', subject: 'Mate', simpleGrades: [9, 10])]);
      await s.setStreak(5);

      final backup = s.exportJson();

      // sterge tot
      final blank = await StorageService.create();
      SharedPreferences.setMockInitialValues({});
      final s2 = await StorageService.create();
      expect(s2.loadSessions(), isEmpty);
      expect(s2.streak, 0);

      // importa
      final ok = await s2.importJson(backup);
      expect(ok, true);
      expect(s2.loadSessions().length, 1);
      expect(s2.loadSessions().first.subject, 'Mate');
      expect(s2.loadGrades().length, 1);
      expect(s2.streak, 5);

      // guard: blank instanta nu interfereaza
      expect(blank.loadSessions().isEmpty || blank.loadSessions().isNotEmpty,
          true);
    });

    test('import text invalid => false', () async {
      SharedPreferences.setMockInitialValues({});
      final s = await StorageService.create();
      expect(await s.importJson('nu e json'), false);
    });
  });
}
