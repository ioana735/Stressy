import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/tracker_provider.dart';
import '../theme/silk.dart';
import 'grades_screen.dart';
import 'home_screen.dart';
import 'plan_screen.dart';
import 'stats_screen.dart';

/// Tab-ul selectat. Permite comutarea din orice ecran (ex. de pe Dashboard
/// spre Plan).
final tabIndexProvider = StateProvider<int>((ref) => 0);

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  static const _tabs = [
    DashboardView(),
    PlanView(),
    GradesView(),
    StatsView(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(tabIndexProvider);
    // reconstruieste cand se schimba tema (altfel fundalul ramane vechi)
    ref.watch(trackerControllerProvider.select((s) => s.settings.darkMode));
    return Scaffold(
      backgroundColor: Silk.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: _tabs),
      ),
      bottomNavigationBar: _BottomNav(
        index: index,
        onTap: (i) => ref.read(tabIndexProvider.notifier).state = i,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.index, required this.onTap});

  static const _items = [
    (Icons.dashboard_rounded, 'Dashboard'),
    (Icons.event_note_rounded, 'Plan'),
    (Icons.grade_rounded, 'Note'),
    (Icons.history_rounded, 'Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(color: Silk.bg),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (i) {
            final selected = i == index;
            final (icon, label) = _items[i];
            return Expanded(
              child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 24,
                      color: selected ? Silk.primary : Silk.onSurfaceVar),
                  const SizedBox(height: 4),
                  Text(label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Silk.primary : Silk.onSurfaceVar,
                      )),
                ],
              ),
            ),
            );
          }),
        ),
      ),
    );
  }
}
