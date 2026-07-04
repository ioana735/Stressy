import 'package:flutter/material.dart';

import '../theme/silk.dart';
import 'home_screen.dart';
import 'plan_screen.dart';
import 'stats_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const _tabs = [
    DashboardView(),
    PlanView(),
    StatsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Silk.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onTap: (i) => setState(() => _index = i),
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
    (Icons.history_rounded, 'Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(color: Silk.bg),
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
