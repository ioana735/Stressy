import 'package:flutter/material.dart';

import '../theme/silk.dart';

/// Grafic cu bare pentru ultimele 7 zile (minute/zi), stil Silk.
class WeeklyChart extends StatelessWidget {
  final List<int> minutesPerDay; // 7 valori, de la acum-6 zile -> azi
  final int goalMinutes;

  const WeeklyChart({
    super.key,
    required this.minutesPerDay,
    required this.goalMinutes,
  });

  static const _labels = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final maxVal = [goalMinutes, ...minutesPerDay]
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 1 << 30);
    final now = DateTime.now();

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final mins = minutesPerDay[i];
          final frac = (mins / maxVal).clamp(0.0, 1.0);
          final reached = mins >= goalMinutes && goalMinutes > 0;
          final weekday = now.subtract(Duration(days: 6 - i)).weekday;
          final isToday = i == 6;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Silk.violet,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('AZI',
                          style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    )
                  else
                    const SizedBox(height: 16),
                  const SizedBox(height: 4),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (_, c) => Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // track inset
                          Container(
                            width: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDE0E8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: frac),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            builder: (_, v, __) => Container(
                              width: 16,
                              height: c.maxHeight * v,
                              decoration: BoxDecoration(
                                color: reached ? Silk.success : Silk.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_labels[(weekday - 1) % 7],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isToday ? Silk.primary : Silk.onSurfaceVar,
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
