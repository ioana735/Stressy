import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../logic/plan_service.dart';
import '../logic/stats_service.dart';
import '../models/exam.dart';
import '../models/planned_block.dart';
import '../models/study_style.dart';
import '../state/tracker_provider.dart';
import '../theme/silk.dart';
import '../widgets/plan_block_tile.dart';

String _fmt(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h > 0 && m > 0) return '${h}h ${m}m';
  if (h > 0) return '${h}h';
  return '${m}m';
}

const _subjects = [
  'Matematică',
  'Programare',
  'Citit',
  'Limbi străine',
  'Examen',
  'Proiect',
];

class PlanView extends ConsumerStatefulWidget {
  const PlanView({super.key});
  @override
  ConsumerState<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends ConsumerState<PlanView> {
  DateTime _selectedDay = StatsService.dayOnly(DateTime.now());
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackerControllerProvider);
    final ctrl = ref.read(trackerControllerProvider.notifier);
    final now = DateTime.now();

    final dayBlocks = PlanService.blocksForDay(state.blocks, _selectedDay);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      children: [
        const Text('Plan',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Silk.onSurface)),
        const SizedBox(height: 4),
        const Text('Planifică-ți din timp ce și cât studiezi.',
            style: TextStyle(color: Silk.onSurfaceVar)),
        const SizedBox(height: 20),

        // --- calendar lunar ---
        Neu(
          padding: const EdgeInsets.all(8),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedMonth,
            currentDay: StatsService.dayOnly(now),
            selectedDayPredicate: (d) => StatsService.dayOnly(d) == _selectedDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Lună'},
            onDaySelected: (sel, foc) => setState(() {
              _selectedDay = StatsService.dayOnly(sel);
              _focusedMonth = foc;
            }),
            onPageChanged: (foc) => _focusedMonth = foc,
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              todayDecoration: BoxDecoration(
                  color: Color(0x335B8DEF), shape: BoxShape.circle),
              todayTextStyle: TextStyle(color: Silk.primary),
              selectedDecoration:
                  BoxDecoration(color: Silk.primary, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Silk.onSurface),
            ),
            eventLoader: (day) {
              final d = StatsService.dayOnly(day);
              final hasExam = state.exams
                  .any((e) => StatsService.dayOnly(e.dateTime) == d);
              final hasPlan =
                  PlanService.blocksForDay(state.blocks, day).isNotEmpty;
              return [if (hasExam) 'exam', if (hasPlan) 'plan'];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (_, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events
                        .map((e) => Container(
                              width: 6,
                              height: 6,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: e == 'exam'
                                    ? const Color(0xFFE5484D)
                                    : Silk.violet,
                              ),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // legenda
        Row(
          children: const [
            _Dot(color: Color(0xFFE5484D)),
            SizedBox(width: 4),
            Text('Examen', style: TextStyle(fontSize: 12, color: Silk.onSurfaceVar)),
            SizedBox(width: 16),
            _Dot(color: Silk.violet),
            SizedBox(width: 4),
            Text('Plan de studiu',
                style: TextStyle(fontSize: 12, color: Silk.onSurfaceVar)),
          ],
        ),
        const SizedBox(height: 20),

        // --- examene apropiate ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Examene',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            GestureDetector(
              onTap: () => _addExamSheet(ctrl),
              child: const Row(children: [
                Icon(Icons.add_circle, color: Silk.primary, size: 20),
                SizedBox(width: 4),
                Text('Adaugă',
                    style: TextStyle(
                        color: Silk.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.exams.isEmpty)
          Neu(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Pune-ți examenele pe calendar.',
                    style: TextStyle(color: Silk.onSurfaceVar)),
              ),
            ),
          )
        else
          ...(([...state.exams]..sort((a, b) => a.dateTime.compareTo(b.dateTime)))
              .map((e) {
            final days = e.daysUntil(now);
            final past = days < 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey('exam_${e.id}'),
                direction: DismissDirection.endToStart,
                background: _delBg(),
                onDismissed: (_) => ctrl.deleteExam(e),
                child: Neu(
                  small: true,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: past
                              ? Silk.onSurfaceVar
                              : const Color(0xFFE5484D),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Silk.onSurface)),
                            Text(
                                '${_fmtDate(e.dateTime)} • ${_fmtTime(e.dateTime)}',
                                style: const TextStyle(
                                    fontSize: 12, color: Silk.onSurfaceVar)),
                          ],
                        ),
                      ),
                      Text(
                        past
                            ? 'trecut'
                            : days == 0
                                ? 'AZI'
                                : 'în $days ${days == 1 ? "zi" : "zile"}',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: past
                                ? Silk.onSurfaceVar
                                : days == 0
                                    ? const Color(0xFFE5484D)
                                    : Silk.primary),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })),
        const SizedBox(height: 24),

        // --- planul zilei selectate ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_dayLabel(_selectedDay),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            GestureDetector(
              onTap: () => _addBlockSheet(ctrl),
              child: const Row(children: [
                Icon(Icons.add_circle, color: Silk.primary, size: 20),
                SizedBox(width: 4),
                Text('Adaugă',
                    style: TextStyle(
                        color: Silk.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (dayBlocks.isEmpty)
          Neu(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Niciun bloc planificat pentru această zi.',
                    style: TextStyle(color: Silk.onSurfaceVar)),
              ),
            ),
          )
        else
          ...dayBlocks.map((b) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey(b.id),
                direction: DismissDirection.endToStart,
                background: _delBg(),
                onDismissed: (_) => ctrl.deleteBlock(b),
                child: Neu(
                  small: true,
                  child: PlanBlockTile(
                    block: b,
                    onToggleDone: () => ctrl.toggleBlockDone(b),
                    onUnitDelta: (d) => ctrl.changeBlockUnits(b, d),
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 16),
        NeuButton(
          onTap: () => _autoPlanSheet(ctrl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.auto_awesome, color: Silk.violet, size: 20),
              SizedBox(width: 10),
              Text('Generează plan automat',
                  style: TextStyle(
                      color: Silk.violet, fontWeight: FontWeight.w700)),
            ],
          ),
        ),

        const SizedBox(height: 32),
        // --- obiective pe materie ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Obiective săptămânale',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800)),
            GestureDetector(
              onTap: () => _goalSheet(ctrl),
              child: const Row(children: [
                Icon(Icons.add_circle, color: Silk.primary, size: 20),
                SizedBox(width: 4),
                Text('Adaugă',
                    style: TextStyle(
                        color: Silk.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.goals.isEmpty)
          Neu(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Setează ținte săptămânale pe materie.',
                    style: TextStyle(color: Silk.onSurfaceVar)),
              ),
            ),
          )
        else
          ...state.goals.map((g) {
            final done = PlanService.weeklyMinutesForSubject(
                state.sessions, g.subject, now);
            final frac = (done / g.weeklyMinutes).clamp(0.0, 1.0);
            final complete = done >= g.weeklyMinutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey('goal_${g.subject}'),
                direction: DismissDirection.endToStart,
                background: _delBg(),
                onDismissed: (_) => ctrl.deleteGoal(g),
                child: Neu(
                  small: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(g.subject,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Silk.onSurface)),
                          Text('${_fmt(done)} / ${_fmt(g.weeklyMinutes)}',
                              style: TextStyle(
                                  color: complete
                                      ? Silk.success
                                      : Silk.onSurfaceVar,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: frac,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFDDE0E8),
                          valueColor: AlwaysStoppedAnimation(
                              complete ? Silk.success : Silk.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _delBg() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
            color: const Color(0xFFE5484D),
            borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete, color: Colors.white),
      );

  // ---------- bottom sheets ----------

  Future<void> _addBlockSheet(TrackerController ctrl) async {
    final block = await showModalBottomSheet<PlannedBlock>(
      context: context,
      backgroundColor: Silk.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _BlockSheet(day: _selectedDay, dayLabel: _dayLabel(_selectedDay)),
    );
    if (block != null) ctrl.addBlock(block);
  }

  Future<void> _addExamSheet(TrackerController ctrl) async {
    final exam = await showModalBottomSheet<Exam>(
      context: context,
      backgroundColor: Silk.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ExamSheet(
          initialDay: _selectedDay,
          initialStyle:
              ref.read(trackerControllerProvider).settings.studyStyle),
    );
    if (exam != null) {
      ctrl.addExam(exam);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(exam.studyHoursTarget != null
              ? 'Examen + plan de studiu adăugat 📚'
              : 'Examen adăugat pe calendar.'),
        ));
      }
    }
  }

  Future<void> _goalSheet(TrackerController ctrl) async {
    final res = await _showSubjectMinutesSheet(
      title: 'Obiectiv săptămânal',
      action: 'Salvează obiectiv',
      minutesLabel: 'PE SĂPTĂMÂNĂ',
      defaultMinutes: 300,
      step: 30,
    );
    if (res != null) ctrl.setGoal(res.$1, res.$2);
  }

  Future<void> _autoPlanSheet(TrackerController ctrl) async {
    final created = await showModalBottomSheet<List<PlannedBlock>>(
      context: context,
      backgroundColor: Silk.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _AutoPlanSheet(
          startDay: _selectedDay,
          initialStyle:
              ref.read(trackerControllerProvider).settings.studyStyle),
    );
    if (created != null && created.isNotEmpty) {
      ctrl.addBlocks(created);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Plan generat: ${created.length} zile.'),
        ));
      }
    }
  }

  Future<(String, int)?> _showSubjectMinutesSheet({
    required String title,
    required String action,
    String minutesLabel = 'DURATĂ',
    int defaultMinutes = 60,
    int step = 15,
  }) {
    return showModalBottomSheet<(String, int)>(
      context: context,
      backgroundColor: Silk.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _SubjectMinutesSheet(
        title: title,
        action: action,
        minutesLabel: minutesLabel,
        defaultMinutes: defaultMinutes,
        step: step,
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _dayLabel(DateTime d) {
    final now = StatsService.dayOnly(DateTime.now());
    final diff = d.difference(now).inDays;
    if (diff == 0) return 'Azi';
    if (diff == 1) return 'Mâine';
    return '${d.day}.${d.month}';
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Selector pentru stilul de invatare (Distribuit / Intensiv).
class StyleSelector extends StatelessWidget {
  final StudyStyle value;
  final ValueChanged<StudyStyle> onChanged;
  const StyleSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: StudyStyle.values.map((s) {
        final selected = s == value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onChanged(s),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? Silk.primary.withValues(alpha: 0.12) : Silk.bg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected ? null : Silk.raisedSoft(),
                border: selected
                    ? Border.all(color: Silk.primary, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Silk.primary
                                    : Silk.onSurface)),
                        Text(s.description,
                            style: const TextStyle(
                                fontSize: 11, color: Silk.onSurfaceVar)),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: Silk.primary, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Sheet pentru adaugarea unui examen pe calendar.
class _ExamSheet extends StatefulWidget {
  final DateTime initialDay;
  final StudyStyle initialStyle;
  const _ExamSheet({required this.initialDay, required this.initialStyle});
  @override
  State<_ExamSheet> createState() => _ExamSheetState();
}

class _ExamSheetState extends State<_ExamSheet> {
  final _ctrl = TextEditingController();
  late DateTime _date = widget.initialDay;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  bool _autoPlan = false;
  int _studyHours = 10;
  late StudyStyle _style = widget.initialStyle;
  late DateTime _notifyFrom =
      StatsService.dayOnly(DateTime.now());

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Adaugă examen',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Silk.onSurface)),
            ),
            const SizedBox(height: 22),
            const Text('MATERIE / EXAMEN',
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
                controller: _ctrl,
                decoration: const InputDecoration(
                    border: InputBorder.none, hintText: 'ex. Examen Analiză'),
              ),
            ),
            const SizedBox(height: 18),
            // data + ora
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 1)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 730)),
                      );
                      if (p != null) {
                        setState(() => _date = StatsService.dayOnly(p));
                      }
                    },
                    child: _field('DATA',
                        '${_date.day}.${_date.month}.${_date.year}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final p = await showTimePicker(
                          context: context, initialTime: _time);
                      if (p != null) setState(() => _time = p);
                    },
                    child: _field('ORA',
                        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // toggle auto-plan
            Neu(
              small: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Generează plan de învățat',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Silk.onSurface)),
                      ),
                      Switch(
                        value: _autoPlan,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Silk.primary,
                        onChanged: (v) => setState(() => _autoPlan = v),
                      ),
                    ],
                  ),
                  if (_autoPlan) ...[
                    const Divider(color: Color(0x11000000)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text('Total ore de studiu:',
                            style: TextStyle(color: Silk.onSurfaceVar)),
                        const Spacer(),
                        NeuButton(
                          padding: const EdgeInsets.all(8),
                          radius: 10,
                          onTap: () => setState(() =>
                              _studyHours = (_studyHours - 1).clamp(1, 300)),
                          child: const Icon(Icons.remove,
                              color: Silk.primary, size: 16),
                        ),
                        SizedBox(
                            width: 48,
                            child: Text('$_studyHours h',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800))),
                        NeuButton(
                          padding: const EdgeInsets.all(8),
                          radius: 10,
                          onTap: () => setState(() =>
                              _studyHours = (_studyHours + 1).clamp(1, 300)),
                          child: const Icon(Icons.add,
                              color: Silk.primary, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: _notifyFrom,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 1)),
                          lastDate: _date,
                        );
                        if (p != null) {
                          setState(
                              () => _notifyFrom = StatsService.dayOnly(p));
                        }
                      },
                      child: _field('NOTIFICĂ-MĂ SĂ ÎNVĂȚ DE LA',
                          '${_notifyFrom.day}.${_notifyFrom.month}.${_notifyFrom.year}'),
                    ),
                    const SizedBox(height: 14),
                    const Text('STIL DE ÎNVĂȚARE',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: Silk.onSurfaceVar)),
                    const SizedBox(height: 8),
                    StyleSelector(
                        value: _style,
                        onChanged: (s) => setState(() => _style = s)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            NeuButton(
              filled: true,
              onTap: () {
                final name = _ctrl.text.trim();
                if (name.isEmpty) return;
                final dt = DateTime(_date.year, _date.month, _date.day,
                    _time.hour, _time.minute);
                Navigator.of(context).pop(Exam(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name,
                  dateTime: dt,
                  notifyFrom: _notifyFrom,
                  studyHoursTarget: _autoPlan ? _studyHours : null,
                  studyStyle: _style,
                ));
              },
              child: const Text('Salvează examenul',
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

  Widget _field(String label, String value) => Neu(
        small: true,
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Silk.onSurfaceVar)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

const _units = ['pagini', 'capitole', 'exerciții', 'seminarii', 'cursuri', 'lecții'];

/// Sheet bogat pentru un task: titlu + ce ai de facut + tinta optionala + timp.
class _BlockSheet extends StatefulWidget {
  final DateTime day;
  final String dayLabel;
  const _BlockSheet({required this.day, required this.dayLabel});
  @override
  State<_BlockSheet> createState() => _BlockSheetState();
}

class _BlockSheetState extends State<_BlockSheet> {
  final _subject = TextEditingController();
  final _note = TextEditingController();
  bool _hasTarget = false;
  int _target = 20;
  String _unit = 'pagini';
  int _minutes = 60;

  @override
  void dispose() {
    _subject.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text('Task — ${widget.dayLabel}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Silk.onSurface)),
            ),
            const SizedBox(height: 20),
            _label('MATERIE'),
            const SizedBox(height: 8),
            NeuInset(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _subject,
                decoration: const InputDecoration(
                    border: InputBorder.none, hintText: 'ex. Programare'),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subjects
                  .map((s) => GestureDetector(
                        onTap: () => setState(() => _subject.text = s),
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
            const SizedBox(height: 18),
            _label('CE AI DE FĂCUT / NOTIȚE'),
            const SizedBox(height: 8),
            NeuInset(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'ex. Citește pag. 20–45, Seminar 3...'),
              ),
            ),
            const SizedBox(height: 18),
            // tinta cantitativa
            Neu(
              small: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Țintă (pagini, exerciții...)',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Silk.onSurface)),
                      ),
                      Switch(
                        value: _hasTarget,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Silk.primary,
                        onChanged: (v) => setState(() => _hasTarget = v),
                      ),
                    ],
                  ),
                  if (_hasTarget) ...[
                    const Divider(color: Color(0x11000000)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NeuButton(
                          padding: const EdgeInsets.all(10),
                          radius: 12,
                          onTap: () => setState(
                              () => _target = (_target - 5).clamp(1, 100000)),
                          child: const Icon(Icons.remove,
                              color: Silk.primary, size: 18),
                        ),
                        SizedBox(
                            width: 70,
                            child: Text('$_target',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800))),
                        NeuButton(
                          padding: const EdgeInsets.all(10),
                          radius: 12,
                          onTap: () => setState(
                              () => _target = (_target + 5).clamp(1, 100000)),
                          child: const Icon(Icons.add,
                              color: Silk.primary, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _units
                          .map((u) => GestureDetector(
                                onTap: () => setState(() => _unit = u),
                                child: Neu(
                                  small: true,
                                  radius: 12,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: Text(u,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: _unit == u
                                              ? Silk.primary
                                              : Silk.onSurfaceVar,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            _label('TIMP ESTIMAT (opțional)'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeuButton(
                  padding: const EdgeInsets.all(12),
                  radius: 14,
                  onTap: () =>
                      setState(() => _minutes = (_minutes - 15).clamp(0, 1440)),
                  child: const Icon(Icons.remove, color: Silk.primary),
                ),
                SizedBox(
                  width: 110,
                  child: Text(_minutes == 0 ? 'fără' : _fmt(_minutes),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                NeuButton(
                  padding: const EdgeInsets.all(12),
                  radius: 14,
                  onTap: () =>
                      setState(() => _minutes = (_minutes + 15).clamp(0, 1440)),
                  child: const Icon(Icons.add, color: Silk.primary),
                ),
              ],
            ),
            const SizedBox(height: 26),
            NeuButton(
              filled: true,
              onTap: () {
                final subject = _subject.text.trim();
                if (subject.isEmpty) return;
                final note = _note.text.trim();
                Navigator.of(context).pop(PlannedBlock(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  date: widget.day,
                  subject: subject,
                  note: note.isEmpty ? null : note,
                  plannedMinutes: _minutes,
                  targetUnits: _hasTarget ? _target : null,
                  unitLabel: _hasTarget ? _unit : null,
                ));
              },
              child: const Text('Adaugă în plan',
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
      style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
          color: Silk.onSurfaceVar));
}

/// Sheet reutilizabil: materie + minute (cu +/-).
class _SubjectMinutesSheet extends StatefulWidget {
  final String title;
  final String action;
  final String minutesLabel;
  final int defaultMinutes;
  final int step;
  const _SubjectMinutesSheet({
    required this.title,
    required this.action,
    required this.minutesLabel,
    required this.defaultMinutes,
    required this.step,
  });

  @override
  State<_SubjectMinutesSheet> createState() => _SubjectMinutesSheetState();
}

class _SubjectMinutesSheetState extends State<_SubjectMinutesSheet> {
  late int _minutes = widget.defaultMinutes;
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
          Center(
            child: Text(widget.title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Silk.onSurface)),
          ),
          const SizedBox(height: 22),
          const Text('MATERIE',
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
              controller: _ctrl,
              decoration: const InputDecoration(
                  border: InputBorder.none, hintText: 'ex. Matematică'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subjects
                .map((s) => GestureDetector(
                      onTap: () => setState(() => _ctrl.text = s),
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
          const SizedBox(height: 22),
          Text(widget.minutesLabel,
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: Silk.onSurfaceVar)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeuButton(
                padding: const EdgeInsets.all(14),
                radius: 16,
                onTap: () => setState(
                    () => _minutes = (_minutes - widget.step).clamp(5, 1440)),
                child: const Icon(Icons.remove, color: Silk.primary),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 120,
                child: Text(_fmt(_minutes),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 24),
              NeuButton(
                padding: const EdgeInsets.all(14),
                radius: 16,
                onTap: () => setState(
                    () => _minutes = (_minutes + widget.step).clamp(5, 1440)),
                child: const Icon(Icons.add, color: Silk.primary),
              ),
            ],
          ),
          const SizedBox(height: 28),
          NeuButton(
            filled: true,
            onTap: () {
              final subject = _ctrl.text.trim();
              if (subject.isEmpty) return;
              Navigator.of(context).pop((subject, _minutes));
            },
            child: Text(widget.action,
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

/// Sheet pentru generatorul automat de plan.
class _AutoPlanSheet extends StatefulWidget {
  final DateTime startDay;
  final StudyStyle initialStyle;
  const _AutoPlanSheet({required this.startDay, required this.initialStyle});
  @override
  State<_AutoPlanSheet> createState() => _AutoPlanSheetState();
}

class _AutoPlanSheetState extends State<_AutoPlanSheet> {
  final _ctrl = TextEditingController();
  int _totalHours = 10;
  late StudyStyle _style = widget.initialStyle;
  late DateTime _from = widget.startDay;
  late DateTime _to = widget.startDay.add(const Duration(days: 4));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _to.difference(_from).inDays + 1;
    final perDay = days > 0 ? (_totalHours * 60 / days).round() : 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text('Generează plan automat',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Silk.onSurface)),
          ),
          const SizedBox(height: 22),
          const Text('MATERIE',
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
              controller: _ctrl,
              decoration: const InputDecoration(
                  border: InputBorder.none, hintText: 'ex. Examen'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _subjects
                .map((s) => GestureDetector(
                      onTap: () => setState(() => _ctrl.text = s),
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
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Total ore: ',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              NeuButton(
                padding: const EdgeInsets.all(10),
                radius: 12,
                onTap: () =>
                    setState(() => _totalHours = (_totalHours - 1).clamp(1, 200)),
                child: const Icon(Icons.remove, color: Silk.primary, size: 18),
              ),
              SizedBox(
                  width: 56,
                  child: Text('$_totalHours h',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800))),
              NeuButton(
                padding: const EdgeInsets.all(10),
                radius: 12,
                onTap: () =>
                    setState(() => _totalHours = (_totalHours + 1).clamp(1, 200)),
                child: const Icon(Icons.add, color: Silk.primary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _dateField('De la', _from, (d) => setState(() {
                        _from = d;
                        if (_to.isBefore(_from)) _to = _from;
                      }))),
              const SizedBox(width: 12),
              Expanded(
                  child: _dateField('Până la', _to, (d) => setState(() {
                        _to = d.isBefore(_from) ? _from : d;
                      }))),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
                '≈ ${_fmt(perDay)} / zi, timp de $days ${days == 1 ? "zi" : "zile"}',
                style: const TextStyle(
                    color: Silk.violet, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 18),
          const Text('STIL DE ÎNVĂȚARE',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: Silk.onSurfaceVar)),
          const SizedBox(height: 8),
          StyleSelector(
              value: _style, onChanged: (s) => setState(() => _style = s)),
          const SizedBox(height: 14),
          NeuButton(
            filled: true,
            onTap: () {
              final subject = _ctrl.text.trim();
              if (subject.isEmpty) return;
              final blocks = PlanService.generatePlan(
                subject: subject,
                totalMinutes: _totalHours * 60,
                from: _from,
                to: _to,
                idSeed: DateTime.now().microsecondsSinceEpoch,
                style: _style,
              );
              Navigator.of(context).pop(blocks);
            },
            child: const Text('Generează',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dateField(String label, DateTime value, ValueChanged<DateTime> onPick) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPick(StatsService.dayOnly(picked));
      },
      child: Neu(
        small: true,
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Silk.onSurfaceVar)),
            const SizedBox(height: 2),
            Text('${value.day}.${value.month}.${value.year}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
