import 'package:flutter_test/flutter_test.dart';
import 'package:stressy/logic/ics_service.dart';
import 'package:stressy/logic/stats_service.dart';
import 'package:stressy/logic/streak_service.dart';
import 'package:stressy/models/exam.dart';
import 'package:stressy/models/planned_block.dart';
import 'package:stressy/models/study_session.dart';

void main() {
  group('StatsService', () {
    final now = DateTime(2026, 7, 26, 14);
    final sessions = [
      StudySession(date: DateTime(2026, 7, 26, 9), minutes: 40),
      StudySession(date: DateTime(2026, 7, 26, 15), minutes: 20),
      StudySession(date: DateTime(2026, 7, 25, 10), minutes: 60),
      StudySession(date: DateTime(2026, 7, 20, 10), minutes: 30),
    ];

    test('minutesOn insumeaza doar ziua ceruta', () {
      expect(StatsService.minutesOn(sessions, DateTime(2026, 7, 26, 23)), 60);
      expect(StatsService.minutesOn(sessions, DateTime(2026, 7, 25)), 60);
      expect(StatsService.minutesOn(sessions, DateTime(2026, 7, 24)), 0);
    });

    test('minutesToday foloseste now', () {
      expect(StatsService.minutesToday(sessions, now), 60);
    });

    test('last7Days are 7 valori, ultima e azi', () {
      final week = StatsService.last7Days(sessions, now);
      expect(week.length, 7);
      expect(week.last, 60); // azi (26)
      expect(week[5], 60); // ieri (25)
      expect(week.first, 30); // acum 6 zile = 20 iul (30 min)
    });

    test('totalMinutes si activeDays', () {
      expect(StatsService.totalMinutes(sessions), 150);
      expect(StatsService.activeDays(sessions), 3); // 26, 25, 20
    });

    test('studiedToday', () {
      expect(StatsService.studiedToday(sessions, now), isTrue);
      expect(
          StatsService.studiedToday(sessions, DateTime(2026, 7, 24)), isFalse);
    });

    test('dayOnly taie ora', () {
      expect(StatsService.dayOnly(DateTime(2026, 7, 26, 23, 59)),
          DateTime(2026, 7, 26));
    });
  });

  group('StreakService', () {
    test('aceeasi zi -> streak neschimbat', () {
      final r = StreakService.registerStudy(
        currentStreak: 5,
        lastStudyDay: DateTime(2026, 7, 26, 8),
        now: DateTime(2026, 7, 26, 20),
      );
      expect(r.streak, 5);
    });

    test('ziua urmatoare -> streak + 1', () {
      final r = StreakService.registerStudy(
        currentStreak: 5,
        lastStudyDay: DateTime(2026, 7, 25),
        now: DateTime(2026, 7, 26),
      );
      expect(r.streak, 6);
    });

    test('gap mai mare de o zi -> reset la 1', () {
      final r = StreakService.registerStudy(
        currentStreak: 5,
        lastStudyDay: DateTime(2026, 7, 23),
        now: DateTime(2026, 7, 26),
      );
      expect(r.streak, 1);
    });

    test('prima sesiune (null) -> 1', () {
      final r = StreakService.registerStudy(
        currentStreak: 0,
        lastStudyDay: null,
        now: DateTime(2026, 7, 26),
      );
      expect(r.streak, 1);
    });

    test('currentValidStreak pastreaza in fereastra, reseteaza dupa', () {
      expect(
        StreakService.currentValidStreak(
          storedStreak: 7,
          lastStudyDay: DateTime(2026, 7, 25),
          now: DateTime(2026, 7, 26),
        ),
        7,
      );
      expect(
        StreakService.currentValidStreak(
          storedStreak: 7,
          lastStudyDay: DateTime(2026, 7, 23),
          now: DateTime(2026, 7, 26),
        ),
        0,
      );
      expect(
        StreakService.currentValidStreak(
          storedStreak: 7,
          lastStudyDay: null,
          now: DateTime(2026, 7, 26),
        ),
        0,
      );
    });
  });

  group('IcsService.allExamsCalendar', () {
    final exams = [
      Exam(
          id: 'e1',
          name: 'Analiză',
          dateTime: DateTime(2026, 8, 20, 9),
          format: ExamFormat.scris),
      Exam(
          id: 'e2',
          name: 'Fizică',
          dateTime: DateTime(2026, 8, 25, 12),
          format: ExamFormat.oral),
    ];
    final blocks = [
      PlannedBlock(
          id: 'b1',
          date: DateTime(2026, 8, 18),
          subject: 'Analiză',
          plannedMinutes: 90,
          examId: 'e1'),
    ];

    test('contine un VCALENDAR valid cu toate examenele', () {
      final ics = IcsService.allExamsCalendar(
        exams: exams,
        blocks: blocks,
        stamp: DateTime(2026, 7, 26, 12),
      );
      expect(ics, startsWith('BEGIN:VCALENDAR'));
      expect(ics.trim(), endsWith('END:VCALENDAR'));
      // cate un eveniment de examen pentru fiecare + un bloc de studiu
      final events = 'BEGIN:VEVENT'.allMatches(ics).length;
      expect(events, 3); // 2 examene + 1 bloc
      expect(ics, contains('Analiză'));
      expect(ics, contains('Fizică'));
      expect(ics, contains('Studiază: Analiză'));
    });

    test('lista goala produce calendar fara evenimente', () {
      final ics = IcsService.allExamsCalendar(
        exams: const [],
        blocks: const [],
        stamp: DateTime(2026, 7, 26),
      );
      expect('BEGIN:VEVENT'.allMatches(ics).length, 0);
    });

    test('blocurile se leaga doar de examenul lor (examId)', () {
      final ics = IcsService.allExamsCalendar(
        exams: [exams.first], // doar e1
        blocks: [
          ...blocks,
          PlannedBlock(
              id: 'b2',
              date: DateTime(2026, 8, 24),
              subject: 'Fizică',
              examId: 'e2'), // apartine lui e2, absent
        ],
        stamp: DateTime(2026, 7, 26),
      );
      expect(ics, contains('Studiază: Analiză'));
      expect(ics, isNot(contains('Studiază: Fizică')));
    });
  });
}
