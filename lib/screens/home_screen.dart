import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/plan_service.dart';
import '../logic/session_runner.dart';
import '../models/exam.dart';
import '../state/tracker_provider.dart';
import '../theme/silk.dart';
import 'root_screen.dart';
import 'settings_screen.dart';
import '../widgets/goal_ring.dart';
import '../widgets/plan_block_tile.dart';
import '../widgets/weekly_chart.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  SessionRunner? _runner;
  String? _subject;
  int _segStartSec = 0; // secunde lucrate la inceputul segmentului materiei curente
  bool _running = false;
  SessionPhase _phase = SessionPhase.work;
  int _displaySec = 0;

  @override
  void dispose() {
    _runner?.dispose();
    super.dispose();
  }

  List<String> _todaySubjects() {
    final blocks = PlanService.blocksForDay(
        ref.read(trackerControllerProvider).blocks, DateTime.now());
    final seen = <String>{};
    final out = <String>[];
    for (final b in blocks) {
      if (seen.add(b.subject.toLowerCase())) out.add(b.subject);
    }
    return out;
  }

  /// Un singur flux: alegi materia (din task-urile de azi sau liber) + durata
  /// + modul, plus pauze optionale.
  Future<void> _openSession() async {
    final cfg = await showModalBottomSheet<_SessionInput>(
      context: context,
      backgroundColor: Silk.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _SessionSheet(todaySubjects: _todaySubjects()),
    );
    if (cfg == null) return;
    if (cfg.mode == _SessionMode.manual) {
      await ref
          .read(trackerControllerProvider.notifier)
          .logSession(cfg.minutes, subject: cfg.subject);
      if (mounted) _toast('Sesiune salvată: ${_fmtMin(cfg.minutes)} ✅');
      return;
    }
    _startRunner(cfg);
  }

  /// Inregistreaza timpul segmentului curent (materia curenta) si muta reperul.
  Future<void> _logSegment() async {
    final r = _runner;
    if (r == null) return;
    final segMin = ((r.workedSeconds - _segStartSec) / 60).round();
    _segStartSec = r.workedSeconds;
    if (segMin >= 1) {
      await ref
          .read(trackerControllerProvider.notifier)
          .logSession(segMin, subject: _subject);
    }
  }

  /// Comuta materia din mers, fara sa opreasca sesiunea.
  Future<void> _switchSubject() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Silk.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _SubjectPickerSheet(
          todaySubjects: _todaySubjects(), current: _subject),
    );
    if (picked == null) return;
    await _logSegment(); // salveaza timpul de pana acum la materia veche
    setState(() => _subject = picked.isEmpty ? null : picked);
    if (mounted) {
      _toast('Acum studiezi: ${_subject ?? "general"} 📚');
    }
  }

  void _startRunner(_SessionInput cfg) {
    _subject = cfg.subject;
    _segStartSec = 0;
    _runner = SessionRunner(
      stopwatch: cfg.mode == _SessionMode.stopwatch,
      targetWorkSeconds: cfg.minutes * 60,
      breaksEnabled: cfg.breaks,
      workBlockSeconds: cfg.workBlock * 60,
      breakBlockSeconds: cfg.breakBlock * 60,
      onTick: (phase, disp) => setState(() {
        _phase = phase;
        _displaySec = disp;
      }),
      onPhaseChange: (newPhase) {
        HapticFeedback.mediumImpact();
        final onBreak = newPhase == SessionPhase.breakTime;
        final title = onBreak ? 'Pauză! ☕' : 'Pauza s-a încheiat 📚';
        final body = onBreak
            ? 'Odihnește-te puțin.'
            : 'Înapoi la treabă — hai că poți!';
        ref.read(notificationProvider).showNow(title, body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                onBreak ? const Color(0xFFF2A93B) : Silk.primary,
            content: Text(onBreak
                ? '☕ Pauză! Odihnește-te.'
                : '📚 Pauza s-a încheiat — înapoi la treabă!'),
          ));
        }
      },
      onFinish: (workedMin) async {
        await _logSegment(); // salveaza ultimul segment
        setState(() => _running = false);
        if (mounted) _toast('Sesiune terminată! 🎉 (${_fmtMin(workedMin)})');
      },
    )..start();
    setState(() {
      _running = true;
      _phase = SessionPhase.work;
    });
  }

  Future<void> _stopRunner() async {
    final total = _runner?.workedMinutes ?? 0;
    await _logSegment(); // salveaza segmentul curent
    _runner?.stop();
    setState(() => _running = false);
    if (mounted && total >= 1) {
      _toast('Sesiune salvată: ${_fmtMin(total)} ✅');
    }
  }

  String _fmtMin(int m) {
    final h = m ~/ 60;
    final mm = m % 60;
    if (h > 0 && mm > 0) return '${h}h ${mm}min';
    if (h > 0) return '${h}h';
    return '${mm}min';
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

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
              Text('Stressy',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Silk.primary)),
              Neu(
                  padding: const EdgeInsets.all(10),
                  radius: 16,
                  small: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SettingsPage())),
                  child: Icon(Icons.settings_rounded,
                      color: Silk.onSurfaceVar, size: 20)),
            ],
          ),
          const SizedBox(height: 24),
          // inel obiectiv
          Center(
            child: GoalRing(
              minutesToday: state.minutesToday,
              goalMinutes: state.goal,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              state.goalReached
                  ? 'Felicitări! Ți-ai atins obiectivul de azi. 🎉'
                  : 'Concentrează-te. Ești la $pct% din obiectivul zilnic.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, color: Silk.onSurfaceVar, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          Center(child: _GoalPicker(goalMinutes: state.goal)),
          const SizedBox(height: 22),
          // buton principal (sus) — deschide alegerea modului; STOP cand ruleaza
          _SessionButton(
            running: _running,
            onBreak: _phase == SessionPhase.breakTime,
            timeLabel: SessionRunner.fmt(_displaySec),
            onStart: _openSession,
            onStop: _stopRunner,
          ),
          if (_running) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _switchSubject,
              child: Neu(
                small: true,
                radius: 16,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_rounded,
                        color: Silk.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('Studiezi: ${_subject ?? "general"}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Silk.onSurface)),
                    const SizedBox(width: 8),
                    Text('• Schimbă',
                        style: TextStyle(
                            color: Silk.primary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 26),
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
                Divider(color: Silk.divider),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text('Progres săptămânal',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Silk.onSurfaceVar,
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    Text('$pct% obiectiv',
                        style: TextStyle(
                            color: Silk.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          // --- Examene apropiate ---
          _ExamsSummary(),
          // --- Azi ai de făcut (plan) ---
          _TodayPlan(),
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
/// Selector de obiectiv zilnic (in ore) direct pe Dashboard.
class _GoalPicker extends ConsumerWidget {
  final int goalMinutes;
  const _GoalPicker({required this.goalMinutes});

  String _fmt(int m) {
    final h = m ~/ 60;
    final mm = m % 60;
    if (h > 0 && mm > 0) return '${h}h ${mm}min';
    if (h > 0) return '${h}h';
    return '${mm}min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(trackerControllerProvider.notifier);
    final settings = ref.read(trackerControllerProvider).settings;
    void set(int m) =>
        ctrl.updateSettings(settings.copyWith(dailyGoalMinutes: m.clamp(30, 1440)));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🎯 Obiectiv:',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Silk.onSurfaceVar)),
        const SizedBox(width: 8),
        NeuButton(
          padding: const EdgeInsets.all(7),
          radius: 12,
          onTap: () => set(goalMinutes - 30),
          child: const Icon(Icons.remove, color: Silk.primary, size: 18),
        ),
        SizedBox(
          width: 64,
          child: Text(_fmt(goalMinutes),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Silk.primary)),
        ),
        NeuButton(
          padding: const EdgeInsets.all(7),
          radius: 12,
          onTap: () => set(goalMinutes + 30),
          child: const Icon(Icons.add, color: Silk.primary, size: 18),
        ),
      ],
    );
  }
}

/// Examenele apropiate pe Dashboard. Avertizeaza daca un examen n-are plan
/// de invatat. Tap -> merge in tab-ul Plan.
class _ExamsSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final exams = ref
        .watch(trackerControllerProvider)
        .exams
        .where((e) => e.daysUntil(now) >= 0)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    if (exams.isEmpty) return const SizedBox.shrink();

    void goToPlan() => ref.read(tabIndexProvider.notifier).state = 1;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Neu(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Examene',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: goToPlan,
                  child: const Text('Vezi tot',
                      style: TextStyle(
                          color: Silk.primary, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...exams.take(3).map((e) {
              final days = e.daysUntil(now);
              final hasPlan = e.hoursPerDay != null && e.hoursPerDay! > 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: goToPlan,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(e.colorValue),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            if (hasPlan)
                              Text('${e.hoursPerDay}h/zi de studiu',
                                  style: const TextStyle(
                                      fontSize: 12, color: Silk.success))
                            else
                              const Text('⚠️ Fără plan — apasă să faci unul',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFFE5748A))),
                          ],
                        ),
                      ),
                      Text(
                        days == 0 ? 'AZI' : 'în $days ${days == 1 ? "zi" : "zile"}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: days == 0
                                ? const Color(0xFFE5484D)
                                : Silk.primary),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TodayPlan extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackerControllerProvider);
    final ctrl = ref.read(trackerControllerProvider.notifier);
    final now = DateTime.now();
    final blocks = PlanService.blocksForDay(state.blocks, now);
    if (blocks.isEmpty) return const SizedBox.shrink();

    bool blockDone(b) {
      if (b.isComplete) return true;
      if (!b.hasTarget && b.plannedMinutes > 0) {
        return PlanService.minutesForSubjectOnDay(
                state.sessions, b.subject, now) >=
            b.plannedMinutes;
      }
      return false;
    }

    final doneCount = blocks.where(blockDone).length;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Neu(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Azi ai de făcut',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('$doneCount/${blocks.length}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Silk.primary)),
              ],
            ),
            const SizedBox(height: 14),
            ...blocks.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PlanBlockTile(
                    block: b,
                    studiedMinutes: PlanService.minutesForSubjectOnDay(
                        state.sessions, b.subject, now),
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

/// Selector de obiectiv zilnic (in ore), direct pe Dashboard.
/// Butonul principal de sesiune. Verde/indigo la start, roșu STOP la lucru,
/// portocaliu „PAUZĂ" în timpul pauzei.
class _SessionButton extends StatelessWidget {
  final bool running;
  final bool onBreak;
  final String timeLabel;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _SessionButton({
    required this.running,
    required this.onBreak,
    required this.timeLabel,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    if (!running) {
      return NeuButton(
        filled: true,
        onTap: onStart,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text('ÎNCEPE SĂ ÎNVEȚI',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5)),
          ],
        ),
      );
    }
    final color = onBreak ? const Color(0xFFF2A93B) : const Color(0xFFE5484D);
    return GestureDetector(
      onTap: onStop,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.4),
                offset: const Offset(0, 6),
                blurRadius: 14),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(onBreak ? Icons.coffee_rounded : Icons.stop_rounded,
                color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              onBreak ? 'PAUZĂ • $timeLabel' : 'STOP • $timeLabel',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5),
            ),
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
      small: true,
      radius: 18,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Silk.onSurfaceVar,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Silk.onSurface)),
            ],
          ),
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
              style: TextStyle(
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
                child: Icon(Icons.remove, color: Silk.primary, size: 18),
              ),
              NeuButton(
                padding: const EdgeInsets.all(10),
                radius: 12,
                onTap: onPlus,
                child: Icon(Icons.add, color: Silk.primary, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _SessionMode { timer, stopwatch, manual }

/// Configurarea sesiunii aleasa in sheet.
class _SessionInput {
  final int minutes; // target (timer) sau durata logata (manual)
  final String? subject;
  final _SessionMode mode;
  final bool breaks;
  final int workBlock; // minute de lucru intre pauze
  final int breakBlock; // minute de pauza
  const _SessionInput(this.minutes, this.subject, this.mode,
      this.breaks, this.workBlock, this.breakBlock);
}

/// Sheet unic: materie + mod (timer/cronometru/fără) + durata + pauze.
class _SessionSheet extends StatefulWidget {
  final List<String> todaySubjects;
  const _SessionSheet({this.todaySubjects = const []});

  @override
  State<_SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<_SessionSheet> {
  int _minutes = 30;
  _SessionMode _mode = _SessionMode.timer;
  bool _breaks = false;
  int _workBlock = 25;
  int _breakBlock = 5;
  final _subjectCtrl = TextEditingController();

  @override
  void dispose() {
    _subjectCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final subject = _subjectCtrl.text.trim();
    Navigator.of(context).pop(_SessionInput(
      _minutes,
      subject.isEmpty ? null : subject,
      _mode,
      _mode == _SessionMode.manual ? false : _breaks,
      _workBlock,
      _breakBlock,
    ));
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
    final showDuration = _mode != _SessionMode.stopwatch;
    final showBreaks = _mode != _SessionMode.manual;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader('Sesiune de studiu'),
            const SizedBox(height: 22),

            // materie
            _label('MATERIE (opțional)'),
            const SizedBox(height: 8),
            NeuInset(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'ex. Matematică, Programare...'),
              ),
            ),
            if (widget.todaySubjects.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Din planul de azi:',
                  style: TextStyle(fontSize: 11, color: Silk.onSurfaceVar)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.todaySubjects
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
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _subjectCtrl.text == s
                                        ? Silk.primary
                                        : Silk.onSurfaceVar)),
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),

            // mod
            _label('CUM VREI SĂ ÎNVEȚI?'),
            const SizedBox(height: 8),
            _modeRow(
                _SessionMode.timer, '⏳', 'Timer',
                'Numărătoare inversă până termini timpul ales'),
            _modeRow(_SessionMode.stopwatch, '⏱️', 'Cronometru',
                'Numără în sus — te oprești când vrei'),

            if (showDuration) ...[
              const SizedBox(height: 16),
              _label(_mode == _SessionMode.manual ? 'CÂT AI STUDIAT?' : 'CÂT TIMP?'),
              const SizedBox(height: 6),
              Center(
                child: Text(_fmtDur(_minutes),
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _DurStepper(
                    label: 'Ore',
                    onMinus: () => setState(
                        () => _minutes = (_minutes - 60).clamp(5, 1440)),
                    onPlus: () => setState(
                        () => _minutes = (_minutes + 60).clamp(5, 1440)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _DurStepper(
                    label: 'Minute',
                    onMinus: () => setState(
                        () => _minutes = (_minutes - 5).clamp(5, 1440)),
                    onPlus: () => setState(
                        () => _minutes = (_minutes + 5).clamp(5, 1440)),
                  )),
                ],
              ),
            ],

            // pauze
            if (showBreaks) ...[
              const SizedBox(height: 16),
              Neu(
                small: true,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Pauze',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Silk.onSurface)),
                        ),
                        Switch(
                          value: _breaks,
                          activeThumbColor: Colors.white,
                          activeTrackColor: Silk.primary,
                          onChanged: (v) => setState(() => _breaks = v),
                        ),
                      ],
                    ),
                    if (_breaks) ...[
                      Divider(color: Silk.divider),
                      const SizedBox(height: 6),
                      _breakRow('Lucrezi', _workBlock,
                          (d) => setState(() =>
                              _workBlock = (_workBlock + d).clamp(5, 120))),
                      const SizedBox(height: 10),
                      _breakRow('Pauză', _breakBlock,
                          (d) => setState(() =>
                              _breakBlock = (_breakBlock + d).clamp(1, 60))),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            NeuButton(
              filled: true,
              onTap: _submit,
              child: Text(
                  _mode == _SessionMode.manual
                      ? 'Salvează'
                      : 'Începe sesiunea',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
          color: Silk.onSurfaceVar));

  Widget _modeRow(_SessionMode m, String emoji, String title, String desc) {
    final selected = _mode == m;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _mode = m),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? Silk.primary.withValues(alpha: 0.12) : Silk.bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected ? null : Silk.raisedSoft(),
            border: selected ? Border.all(color: Silk.primary, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Silk.primary : Silk.onSurface)),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 11, color: Silk.onSurfaceVar)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: Silk.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _breakRow(String label, int value, ValueChanged<int> onDelta) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: TextStyle(color: Silk.onSurfaceVar))),
        NeuButton(
          padding: const EdgeInsets.all(8),
          radius: 10,
          onTap: () => onDelta(label == 'Pauză' ? -1 : -5),
          child: Icon(Icons.remove, color: Silk.primary, size: 16),
        ),
        SizedBox(
            width: 60,
            child: Text('$value min',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800))),
        NeuButton(
          padding: const EdgeInsets.all(8),
          radius: 10,
          onTap: () => onDelta(label == 'Pauză' ? 1 : 5),
          child: Icon(Icons.add, color: Silk.primary, size: 16),
        ),
      ],
    );
  }
}

/// Sheet pentru a comuta materia in timpul sesiunii (din task-urile de azi
/// sau scriind liber).
class _SubjectPickerSheet extends StatefulWidget {
  final List<String> todaySubjects;
  final String? current;
  const _SubjectPickerSheet({required this.todaySubjects, this.current});

  @override
  State<_SubjectPickerSheet> createState() => _SubjectPickerSheetState();
}

class _SubjectPickerSheetState extends State<_SubjectPickerSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
          const SheetHeader('Pe ce comuți?'),
          const SizedBox(height: 20),
          if (widget.todaySubjects.isNotEmpty) ...[
            Text('Task-urile de azi:',
                style: TextStyle(fontSize: 11, color: Silk.onSurfaceVar)),
            const SizedBox(height: 10),
            ...widget.todaySubjects.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(s),
                    child: Neu(
                      small: true,
                      radius: 14,
                      child: Row(
                        children: [
                          Icon(Icons.menu_book_rounded,
                              color: Silk.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(s,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Silk.onSurface))),
                          if (widget.current?.toLowerCase() == s.toLowerCase())
                            Text('acum',
                                style: TextStyle(
                                    fontSize: 12, color: Silk.onSurfaceVar)),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 12),
          ],
          Text('Sau scrie o materie:',
              style: TextStyle(fontSize: 11, color: Silk.onSurfaceVar)),
          const SizedBox(height: 8),
          NeuInset(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                  border: InputBorder.none, hintText: 'ex. Română'),
              onSubmitted: (v) =>
                  Navigator.of(context).pop(v.trim()),
            ),
          ),
          const SizedBox(height: 20),
          NeuButton(
            filled: true,
            onTap: () => Navigator.of(context).pop(_ctrl.text.trim()),
            child: Text('Comută',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
