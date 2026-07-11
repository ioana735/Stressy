import 'package:flutter_test/flutter_test.dart';
import 'package:stressy/logic/grades_service.dart';
import 'package:stressy/models/subject_grade.dart';

void main() {
  group('SubjectGrade.finalGrade', () {
    test('note simple => medie aritmetica', () {
      final g = SubjectGrade(
          id: '1', subject: 'Mate', simpleGrades: [8, 9, 10, 7]);
      expect(g.finalGrade, closeTo(8.5, 0.001));
    });

    test('componente % => medie ponderata', () {
      final g = SubjectGrade(id: '2', subject: 'Info', components: const [
        GradeComponent(name: 'Examen', grade: 9, percent: 60),
        GradeComponent(name: 'Lab', grade: 10, percent: 40),
      ]);
      expect(g.finalGrade, closeTo(9.4, 0.001));
    });

    test('nota directa', () {
      final g = SubjectGrade(id: '3', subject: 'X', directGrade: 9.5);
      expect(g.finalGrade, 9.5);
    });

    test('fara nimic => null', () {
      final g = SubjectGrade(id: '4', subject: 'Y');
      expect(g.finalGrade, isNull);
    });
  });

  group('GradesService', () {
    final gs = [
      SubjectGrade(id: '1', subject: 'A', directGrade: 10, credits: 6),
      SubjectGrade(id: '2', subject: 'B', directGrade: 8, credits: 2),
      SubjectGrade(id: '3', subject: 'C'), // fara nota -> ignorat
    ];

    test('media aritmetica ignora materiile fara nota', () {
      expect(GradesService.arithmetic(gs), closeTo(9.0, 0.001));
    });

    test('media ponderata pe credite', () {
      // (10*6 + 8*2) / (6+2) = 76/8 = 9.5
      expect(GradesService.creditWeighted(gs), closeTo(9.5, 0.001));
    });

    test('total credite doar pentru materii cu nota', () {
      expect(GradesService.totalCredits(gs), 8);
    });

    test('perioade distincte sortate', () {
      final list = [
        SubjectGrade(id: '1', subject: 'A', year: 2, semester: 1),
        SubjectGrade(id: '2', subject: 'B', year: 1, semester: 2),
        SubjectGrade(id: '3', subject: 'C', year: 1, semester: 2),
      ];
      final p = GradesService.periods(list);
      expect(p, [(1, 2), (2, 1)]);
    });

    test('liste goale => null', () {
      expect(GradesService.arithmetic([]), isNull);
      expect(GradesService.creditWeighted([]), isNull);
    });
  });

  group('SubjectGrade JSON', () {
    test('round-trip pastreaza datele', () {
      final g = SubjectGrade(
        id: '9',
        subject: 'Fizică',
        year: 2,
        semester: 1,
        credits: 5,
        components: const [
          GradeComponent(name: 'E', grade: 9, percent: 70),
          GradeComponent(name: 'S', grade: 8, percent: 30),
        ],
      );
      final back = SubjectGrade.fromJson(g.toJson());
      expect(back.subject, 'Fizică');
      expect(back.credits, 5);
      expect(back.components.length, 2);
      expect(back.finalGrade, closeTo(g.finalGrade!, 0.001));
    });
  });
}
