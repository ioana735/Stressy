import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/plan_service.dart';
import '../logic/study_timer.dart';
import '../state/tracker_provider.dart';
import '../theme/silk.dart';
import '../widgets/goal_ring.dart';
import '../widgets/plan_block_tile.dart';
import '../widgets/weekly_chart.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  StudyTimer? _timer;
  Duration _remaining = const Duration(minutes: 25);
  bool _running = false;

  @override
  void dispose() {
    _timer?.dispose();
    super.dispose();
  }

  /// Cere materia (optional), apoi porneste cronometrul.
  Future<void> _promptStart() async {
    final result = await showModalBottomSheet<_SessionInput>(
      context: context,
      backgroundColor: Silk.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _SessionSheet(forTimer: true),
    );
    if (result != null) _startTimer(result.subject);
  }

  void _startTimer(String? subject) {
    _timer = StudyTimer(
      sessionMinutes: 25,
      onStart: () => setState(() => _running = true),
      onTick: (r) => setState(() => _remaining = r),
      onComplete: (mins) async {
        await ref
            .read(trackerControllerProvider.notifier)
            .logSession(mins, subject: subject);
        setState(() {
          _running = false;
          _remaining = const Duration(minutes: 25);
        });
        if (mounted) _toast('Sesiune salvată: $mins min 🎉');
      },
      onAbort: () => setState(() {
        _running = false;
        _remaining = const Duration(minutes: 25);
      }),
    )..start();
  }

  void _stopTimer() => _timer?.abort();

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  Future<void> _addManual() async {
    final result = await showModalBottomSheet<_SessionInput>(
      context: context,
      backgroundColor: Silk.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _SessionSheet(forTimer: false),
    );
    if (result != null && result.minutes > 0) {
      await ref
          .read(trackerControllerProvider.notifier)
          .logSession(result.minutes, subject: result.subject);
      if (mounted) _toast('Adăugat: ${result.minutes} min');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackerControllerProvider);
    final pct = (state.goalProgress * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Neu(
                    padding: EdgeInsets.all(8),
                    radius: 16,
                    small: true,
                    child: Icon(Icons.person_rounded,
                        color: Silk.primary, size: 22)),
                const SizedBox(width: 12),
                Text('Stressy',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Silk.primary)),
              ]),
              const Neu(
                  padding: EdgeInsets.all(10),
                  radius: 16,
                  small: true,
                  child: Icon(Icons.settings_rounded,
                      color: Silk.onSurfaceVar, size: 20)),
            ],
          ),
          const SizedBox(height: 28),
          // inel obiectiv
          Center(
            child: GoalRing(
              minutesToday: state.minutesToday,
              goalMinutes: state.goal,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              state.goalReached
                  ? 'Felicitări! Ți-ai atins obiectivul de azi. 🎉'
                  : 'Concentrează-te. Ești la $pct% din obiectivul zilnic.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: Silk.onSurfaceVar, height: 1.4),
            ),
          ),
          const SizedBox(height: 28),
          // carduri
          Row(
            children: [
              Expanded(
                  child: _MiniStat(
                      emoji: '🔥',
                      label: 'Streak',
                      value:
                          '${state.streak} ${state.streak == 1 ? "zi" : "zile"}')),
              const SizedBox(width: 16),
              Expanded(
                  child: _MiniStat(
                      emoji: '📚',
                      label: 'Total',
                      value: _hours(state.totalMinutes))),
            ],
          ),
          const SizedBox(height: 20),
          // grafic
          Neu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WeeklyChart(
                    minutesPerDay: state.last7Days, goalMinutes: state.goal),
                const SizedBox(height: 12),
                const Divider(color: Color(0x11000000)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Progres săptămânal',
                        style: TextStyle(
                            color: Silk.onSurfaceVar,
                            fontWeight: FontWeight.w500)),
                    Text('$pct% obiectiv',
                        style: const TextStyle(
                            color: Silk.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          // --- Azi ai de făcut (plan) ---
          _TodayPlan(),
          const SizedBox(height: 28),
          // buton principal
          NeuButton(
            filled: !_running,
            onTap: _running ? _stopTimer : _promptStart,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_running ? Icons.stop_rounded : Icons.timer_outlined,
                    color: _running ? Silk.primary : Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  _running
                      ? 'STOP  •  ${StudyTimer.format(_remaining)}'
                      : 'START STUDY SESSION',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _running ? Silk.primary : Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _addManual,
              child: Text('+ Adaugă sesiune manual',
                  style: TextStyle(
                      color: Silk.primary, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _hours(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

/// Lista cu ce ai planificat pentru azi (din tab-ul Plan). Apare doar daca
/// exista blocuri planificate azi.
class _TodayPlan extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackerControllerProvider);
    final ctrl = ref.read(trackerControllerProvider.notifier);
    final now = DateTime.now();
    final blocks = PlanService.blocksForDay(state.blocks, now);
    if (blocks.isEmpty) return const SizedBox.shrink();

    final doneCount = blocks.where((b) => b.isComplete).length;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Neu(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Azi ai de făcut',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('$doneCount/${blocks.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: Silk.primary)),
              ],
            ),
            const SizedBox(height: 14),
            ...blocks.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlanBlockTile(
                    block: b,
                    onToggleDone: () => ctrl.toggleBlockDone(b),
                    onUnitDelta: (d) => ctrl.changeBlockUnits(b, d),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _MiniStat(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Neu(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  color: Silk.onSurfaceVar,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Silk.onSurface)),
        ],
      ),
    );
  }
}

/// Stepper cu eticheta (Ore / Minute) si butoane +/-.
class _DurStepper extends StatelessWidget {
  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  const _DurStepper(
      {required this.label, required this.onMinus, required this.onPlus});

  @override
  Widget build(BuildContext context) {
    return Neu(
      small: true,
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Silk.onSurfaceVar)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              NeuButton(
                padding: const EdgeInsets.all(10),
                radius: 12,
                onTap: onMinus,
                child: const Icon(Icons.remove, color: Silk.primary, size: 18),
              ),
              NeuButton(
                padding: const EdgeInsets.all(10),
                radius: 12,
                onTap: onPlus,
                child: const Icon(Icons.add, color: Silk.primary, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rezultatul bottom sheet-ului: durata + materia.
class _SessionInput {
  final int minutes;
  final String? subject;
  const _SessionInput(this.minutes, this.subject);
}

/// Materii sugerate (chip-uri rapide).
const _subjectSuggestions = [
  'Matematică',
  'Programare',
  'Citit',
  'Limbi străine',
  'Examen',
  'Proiect',
];

class _SessionSheet extends StatefulWidget {
  /// true = inainte de cronometru (nu cere minute); false = adaugare manuala.
  final bool forTimer;
  const _SessionSheet({required this.forTimer});

  @override
  State<_SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<_SessionSheet> {
  int _minutes = 30;
  final _subjectCtrl = TextEditingController();

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final subject = _subjectCtrl.text.trim();
    Navigator.of(context).pop(
        _SessionInput(_minutes, subject.isEmpty ? null : subject));
  }

  String _fmtDur(int m) {
    final h = m ~/ 60;
    final mm = m % 60;
    if (h > 0 && mm > 0) return '${h}h ${mm}min';
    if (h > 0) return '${h}h';
    return '${mm}min';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
                widget.forTimer ? 'Ce studiezi?' : 'Adaugă sesiune',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Silk.onSurface)),
          ),
          const SizedBox(height: 22),

          // câmp materie
          const Text('MATERIE (opțional)',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: Silk.onSurfaceVar)),
          const SizedBox(height: 8),
          NeuInset(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'ex. Matematică, Programare...',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subjectSuggestions
                .map((s) => GestureDetector(
                      onTap: () => setState(() {
                        _subjectCtrl.text = s;
                      }),
                      child: Neu(
                        small: true,
                        radius: 12,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Silk.onSurfaceVar,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),

          // selector durata (ore + minute, doar la adaugare manuala)
          if (!widget.forTimer) ...[
            const SizedBox(height: 22),
            const Text('DURATĂ',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: Silk.onSurfaceVar)),
            const SizedBox(height: 6),
            Center(
              child: Text(_fmtDur(_minutes),
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _DurStepper(
                  label: 'Ore',
                  onMinus: () =>
                      setState(() => _minutes = (_minutes - 60).clamp(5, 1440)),
                  onPlus: () =>
                      setState(() => _minutes = (_minutes + 60).clamp(5, 1440)),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _DurStepper(
                  label: 'Minute',
                  onMinus: () =>
                      setState(() => _minutes = (_minutes - 5).clamp(5, 1440)),
                  onPlus: () =>
                      setState(() => _minutes = (_minutes + 5).clamp(5, 1440)),
                )),
              ],
            ),
          ],

          const SizedBox(height: 28),
          NeuButton(
            filled: true,
            onTap: _submit,
            child: Text(widget.forTimer ? 'Începe sesiunea' : 'Salvează',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
