import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/stats_service.dart';
import '../models/exam.dart';
import '../models/study_session.dart';
import '../state/tracker_provider.dart';
import '../theme/silk.dart';
import '../widgets/result_celebration.dart';

class StatsView extends ConsumerWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackerControllerProvider);
    final ctrl = ref.read(trackerControllerProvider.notifier);

    final sessions = [...state.sessions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final grouped = <DateTime, List<StudySession>>{};
    for (final s in sessions) {
      grouped.putIfAbsent(StatsService.dayOnly(s.date), () => []).add(s);
    }
    final days = grouped.keys.toList();

    // ziua cea mai productiva
    final bestDay = grouped.entries.fold<MapEntry<DateTime, int>?>(null, (b, e) {
      final tot = e.value.fold(0, (s, x) => s + x.minutes);
      if (b == null || tot > b.value) return MapEntry(e.key, tot);
      return b;
    });

    // promovabilitate (doar examene marcate)
    final decided =
        state.exams.where((e) => e.result != ExamResult.pending).toList();
    final passed =
        decided.where((e) => e.result == ExamResult.passed).length;
    final passRate =
        decided.isEmpty ? 0 : (passed / decided.length * 100).round();

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

        // --- Promovabilitate ---
        if (decided.isNotEmpty) ...[
          _PassRateCard(
            passRate: passRate,
            passed: passed,
            total: decided.length,
          ),
          const SizedBox(height: 24),
        ],

        // --- Rezultate examene ---
        if (state.exams.isNotEmpty) ...[
          Text('Examenele mele',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...([...state.exams]..sort((a, b) => b.dateTime.compareTo(a.dateTime)))
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExamResultTile(
                      exam: e,
                      onSet: (r) async {
                        await ctrl.setExamResult(e, r);
                        if (context.mounted && r != ExamResult.pending) {
                          await showResultCelebration(context,
                              passed: r == ExamResult.passed);
                        }
                      },
                    ),
                  )),
          const SizedBox(height: 24),
        ],

        if (sessions.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                  'Încă nicio sesiune.\nApasă START pe Dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Silk.onSurfaceVar)),
            ),
          )
        else
          ...days.expand((day) {
            final items = grouped[day]!;
            final total = items.fold(0, (s, x) => s + x.minutes);
            return [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dayLabel(day).toUpperCase(),
                        style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: Silk.onSurfaceVar)),
                    Text('$total min',
                        style: TextStyle(
                            color: Silk.primary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              ...items.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey(
                          s.date.toIso8601String() + s.minutes.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                            color: const Color(0xFFE5484D),
                            borderRadius: BorderRadius.circular(20)),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => ctrl.deleteSession(s),
                      child: Neu(
                        small: true,
                        radius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Neu(
                                small: true,
                                radius: 14,
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.psychology_outlined,
                                    color: Silk.primary, size: 22)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.subject ?? 'Sesiune de studiu',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Silk.onSurface)),
                                  Text(_time(s.date),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Silk.onSurfaceVar)),
                                ],
                              ),
                            ),
                            Text('${s.minutes} min',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Silk.onSurface)),
                          ],
                        ),
                      ),
                    ),
                  )),
            ];
          }),
      ],
    );
  }

  String _hours(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static const _months = [
    'ian', 'feb', 'mar', 'apr', 'mai', 'iun',
    'iul', 'aug', 'sep', 'oct', 'noi', 'dec'
  ];

  String _dayLabel(DateTime d) {
    final now = StatsService.dayOnly(DateTime.now());
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Azi';
    if (diff == 1) return 'Ieri';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }
}

/// Card cu rata de promovare (câte examene ai trecut din cele susținute).
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
                child: Text('$passed din $total examene',
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

class _ExamResultTile extends StatelessWidget {
  final Exam exam;
  final ValueChanged<ExamResult> onSet;
  const _ExamResultTile({required this.exam, required this.onSet});

  @override
  Widget build(BuildContext context) {
    final passed = exam.result == ExamResult.passed;
    final failed = exam.result == ExamResult.failed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Silk.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(passed ? '🏆' : (failed ? '🌱' : '🎓'),
                  style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exam.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Silk.onSurface)),
                    Text(
                        '${exam.dateTime.day}.${exam.dateTime.month}.${exam.dateTime.year}',
                        style: TextStyle(
                            fontSize: 12, color: Silk.onSurfaceVar)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ResultBtn(
                  label: 'Am trecut',
                  emoji: '✅',
                  selected: passed,
                  color: Silk.success,
                  onTap: () => onSet(ExamResult.passed),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResultBtn(
                  label: 'N-am trecut',
                  emoji: '💪',
                  selected: failed,
                  color: const Color(0xFFE5748A),
                  onTap: () => onSet(ExamResult.failed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultBtn extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ResultBtn({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : Silk.track,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$emoji  $label',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : Silk.onSurfaceVar)),
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
