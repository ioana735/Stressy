import 'package:flutter_test/flutter_test.dart';
import 'package:stressy/logic/plan_service.dart';
import 'package:stressy/logic/stats_service.dart';
import 'package:stressy/logic/streak_service.dart';
import 'package:stressy/models/study_session.dart';
import 'package:stressy/models/study_style.dart';

void main() {
  group('StatsService', () {
    final base = DateTime(2026, 1, 7, 10); // miercuri
    final sessions = [
      StudySession(date: DateTime(2026, 1, 7, 9), minutes: 30),
      StudySession(date: DateTime(2026, 1, 7, 14), minutes: 45),
      StudySession(date: DateTime(2026, 1, 5, 11), minutes: 60),
    ];

    test('minutesToday insumeaza sesiunile de azi', () {
      expect(StatsService.minutesToday(sessions, base), 75);
    });

    test('last7Days are 7 valori cu azi la final', () {
      final w = StatsService.last7Days(sessions, base);
      expect(w.length, 7);
      expect(w.last, 75); // azi
    });

    test('totalMinutes si activeDays', () {
      expect(StatsService.totalMinutes(sessions), 135);
      expect(StatsService.activeDays(sessions), 2);
    });

    test('studiedToday', () {
      expect(StatsService.studiedToday(sessions, base), true);
      expect(StatsService.studiedToday([], base), false);
    });
  });

  group('StreakService', () {
    test('zi consecutiva creste streak-ul', () {
      final r = StreakService.registerStudy(
        currentStreak: 3,
        lastStudyDay: DateTime(2026, 1, 1),
        now: DateTime(2026, 1, 2, 9),
      );
      expect(r.streak, 4);
    });

    test('gap de 2 zile reseteaza streak-ul', () {
      final r = StreakService.registerStudy(
        currentStreak: 3,
        lastStudyDay: DateTime(2026, 1, 1),
        now: DateTime(2026, 1, 4),
      );
      expect(r.streak, 1);
    });

    test('streak invalid dupa gap', () {
      final v = StreakService.currentValidStreak(
        storedStreak: 5,
        lastStudyDay: DateTime(2026, 1, 1),
        now: DateTime(2026, 1, 5),
      );
      expect(v, 0);
    });
  });

  group('PlanService', () {
    test('generatePlan distribuie totalul pe zile', () {
      final blocks = PlanService.generatePlan(
        subject: 'Mate',
        totalMinutes: 600, // 10h
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 5), // 5 zile
        idSeed: 1,
      );
      expect(blocks.length, 5);
      expect(blocks.fold(0, (s, b) => s + b.plannedMinutes), 600);
      expect(blocks.every((b) => b.subject == 'Mate'), true);
    });

    test('cramming pune mai mult spre final, total pastrat', () {
      final blocks = PlanService.generatePlan(
        subject: 'Examen',
        totalMinutes: 600,
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 1, 5),
        idSeed: 1,
        style: StudyStyle.cramming,
      );
      expect(blocks.fold(0, (s, b) => s + b.plannedMinutes), 600);
      // ultima zi trebuie sa aiba mai mult decat prima
      expect(blocks.last.plannedMinutes,
          greaterThan(blocks.first.plannedMinutes));
    });

    test('weeklyMinutesForSubject insumeaza doar materia si saptamana', () {
      final now = DateTime(2026, 1, 7); // miercuri
      final sessions = [
        StudySession(date: DateTime(2026, 1, 5), minutes: 60, subject: 'Mate'),
        StudySession(date: DateTime(2026, 1, 6), minutes: 30, subject: 'mate'),
        StudySession(date: DateTime(2026, 1, 6), minutes: 30, subject: 'Citit'),
      ];
      expect(
          PlanService.weeklyMinutesForSubject(sessions, 'Mate', now), 90);
    });
  });
}
