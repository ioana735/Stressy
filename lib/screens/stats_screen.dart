import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/stats_service.dart';
import '../models/study_session.dart';
import '../models/subject_grade.dart';
import '../state/tracker_provider.dart';
import '../theme/silk.dart';
import 'root_screen.dart' show tabIndexProvider;

class StatsView extends ConsumerWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackerControllerProvider);

    final sessions = [...state.sessions];
    final grouped = <DateTime, List<StudySession>>{};
    for (final s in sessions) {
      grouped.putIfAbsent(StatsService.dayOnly(s.date), () => []).add(s);
    }

    // ziua cea mai productiva
    final bestDay = grouped.entries.fold<MapEntry<DateTime, int>?>(null, (b, e) {
      final tot = e.value.fold(0, (s, x) => s + x.minutes);
      if (b == null || tot > b.value) return MapEntry(e.key, tot);
      return b;
    });

    // promovabilitate + materii slabe, calculate direct din notele reale (Note)
    final graded =
        state.grades.where((g) => g.finalGrade != null).toList();
    final passedGrades = graded.where((g) => g.finalGrade! >= 5).length;
    final passRate = graded.isEmpty
        ? 0
        : (passedGrades / graded.length * 100).round();
    final weakSubjects = graded.where((g) => g.finalGrade! < 5).toList()
      ..sort((a, b) => a.finalGrade!.compareTo(b.finalGrade!));

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      children: [
        Text('Statistici',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Silk.onSurface)),
        const SizedBox(height: 18),

        // card sumar
        Neu(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.calendar_month_rounded,
                    size: 18, color: Silk.primary),
                SizedBox(width: 8),
                Text('PERFORMANȚĂ GENERALĂ',
                    style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w800,
                        color: Silk.primary)),
              ]),
              const SizedBox(height: 18),
              _BigStat(
                  label: 'TIMP TOTAL DE FOCUS',
                  value: _hours(state.totalMinutes)),
              const SizedBox(height: 16),
              _BigStat(
                  label: 'ZILE ACTIVE', value: '${state.activeDays}'),
              const SizedBox(height: 16),
              _BigStat(
                label: 'CEA MAI BUNĂ ZI',
                value: bestDay == null
                    ? '—'
                    : _hours(bestDay.value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Promovabilitate (din note) ---
        if (graded.isNotEmpty) ...[
          _PassRateCard(
            passRate: passRate,
            passed: passedGrades,
            total: graded.length,
          ),
          const SizedBox(height: 24),
        ],

        // --- Materii sub 5, de invatat mai mult ---
        if (weakSubjects.isNotEmpty) ...[
          Text('Ai nevoie să înveți mai mult la',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...weakSubjects.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => ref.read(tabIndexProvider.notifier).state = 2,
                  child: Neu(
                    small: true,
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(g.subject,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Silk.onSurface)),
                        ),
                        Text(g.finalGrade!.toStringAsFixed(2),
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFE5484D))),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 24),
        ],

      ],
    );
  }

  String _hours(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

}

/// Card cu rata de promovare (câte materii cu notă >= 5 din cele notate).
class _PassRateCard extends StatelessWidget {
  final int passRate;
  final int passed;
  final int total;
  const _PassRateCard(
      {required this.passRate, required this.passed, required this.total});

  @override
  Widget build(BuildContext context) {
    final good = passRate >= 50;
    final color = good ? Silk.success : const Color(0xFFE5748A);
    final msg = passRate == 100
        ? 'Perfect! Le-ai trecut pe toate. 🏆'
        : good
            ? 'Bravo! Te descurci bine. 💪'
            : 'Nu renunța — urmează mai bine. 💜';

    return Neu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.emoji_events_rounded, size: 18, color: Silk.primary),
            SizedBox(width: 8),
            Text('PROMOVABILITATE',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: Silk.primary)),
          ]),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$passRate%',
                  style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1)),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('$passed din $total materii',
                    style: TextStyle(
                        fontSize: 14, color: Silk.onSurfaceVar)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : passed / total,
              minHeight: 10,
              backgroundColor: Silk.track,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),
          Text(msg,
              style: TextStyle(
                  fontSize: 13, color: Silk.onSurfaceVar)),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  const _BigStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: Silk.onSurfaceVar)),
          Text(value,
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Silk.primary)),
        ],
      );
}
