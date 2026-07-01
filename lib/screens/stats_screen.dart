import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/stats_service.dart';
import '../models/study_session.dart';
import '../state/tracker_provider.dart';
import '../theme/silk.dart';

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

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      children: [
        const Text('Statistici',
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
              Row(children: const [
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

        if (sessions.isEmpty)
          const Padding(
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
                        style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: Silk.onSurfaceVar)),
                    Text('$total min',
                        style: const TextStyle(
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
                        child: const Icon(Icons.delete, color: Colors.white),
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
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Silk.onSurface)),
                                  Text(_time(s.date),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Silk.onSurfaceVar)),
                                ],
                              ),
                            ),
                            Text('${s.minutes} min',
                                style: const TextStyle(
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

  String _dayLabel(DateTime d) {
    final now = StatsService.dayOnly(DateTime.now());
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Azi';
    if (diff == 1) return 'Ieri';
    return '${d.day}.${d.month}.${d.year}';
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
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                  color: Silk.onSurfaceVar)),
          Text(value,
              style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Silk.primary)),
        ],
      );
}
