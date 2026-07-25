import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../logic/downloader.dart';
import '../logic/ics_service.dart';
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
        Text('Plan',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Silk.onSurface)),
        const SizedBox(height: 4),
        Text('Planifică-ți din timp ce și cât studiezi.',
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
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: Silk.onSurface),
            ),
            eventLoader: (day) {
              final d = StatsService.dayOnly(day);
              // fiecare examen -> culoarea lui; plan -> violet
              final markers = <Object>[
                for (final e in state.exams)
                  if (StatsService.dayOnly(e.dateTime) == d) Color(e.colorValue),
              ];
              if (PlanService.blocksForDay(state.blocks, day).isNotEmpty) {
                markers.add('plan');
              }
              return markers;
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (_, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(4).map((e) {
                      final color = e is Color ? e : Silk.violet;
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: color),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        // legenda
        Row(
          children: [
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
            Text('Examene',
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
            child: Center(
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
                  onTap: () => _addExamSheet(ctrl, edit: e),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: past ? Silk.onSurfaceVar : Color(e.colorValue),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.school_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Silk.onSurface)),
                            Text(
                                '${e.kindLabel}${e.format != ExamFormat.none ? " • ${e.format.label}" : ""} · ${_fmtDate(e.dateTime)} ${_fmtTime(e.dateTime)}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 12, color: Silk.onSurfaceVar)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _exportToCalendar(e),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.calendar_month_rounded,
                              color: Silk.primary, size: 22),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                style: TextStyle(
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
            child: Center(
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
                    studiedMinutes: PlanService.minutesForSubjectOnDay(
                        state.sessions, b.subject, b.date),
                    onToggleDone: () => ctrl.toggleBlockDone(b),
                    onUnitDelta: (d) => ctrl.changeBlockUnits(b, d),
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
        child: Icon(Icons.delete, color: Colors.white),
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

  /// Exporta examenul + planul lui ca fisier .ics (Calendar iOS/Android).
  Future<void> _exportToCalendar(Exam e) async {
    final state = ref.read(trackerControllerProvider);
    final blocks = state.blocks.where((b) => b.examId == e.id).toList();
    final ics = IcsService.examCalendar(
      exam: e,
      blocks: blocks,
      stamp: DateTime.now(),
      reminderHour: state.settings.primaryHour,
    );
    final safeName =
        e.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final ok = await downloadText('stressy_$safeName.ics', ics, 'text/calendar');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(ok
            ? 'Calendar descărcat — deschide-l ca să-l adaugi 📅'
            : 'Exportul în calendar merge pe web/telefon.'),
      ));
    }
  }

  /// Adauga sau (daca [edit] != null) editeaza un examen.
  Future<void> _addExamSheet(TrackerController ctrl, {Exam? edit}) async {
    final exam = await showModalBottomSheet<Exam>(
      context: context,
      backgroundColor: Silk.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ExamSheet(
          initialDay: _selectedDay,
          initialStyle:
              ref.read(trackerControllerProvider).settings.studyStyle,
          existing: edit,
          onDelete: edit == null ? null : () => ctrl.deleteExam(edit)),
    );
    if (exam == null) return;
    if (edit != null) {
      ctrl.updateExam(exam);
    } else {
      ctrl.addExam(exam);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(edit != null ? 'Examen actualizat ✏️' : 'Examen adăugat 📅'),
      ));
    }
  }

  String _fmtDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static const _months = [
    'ian', 'feb', 'mar', 'apr', 'mai', 'iun',
    'iul', 'aug', 'sep', 'oct', 'noi', 'dec'
  ];
  static const _weekdays = ['Lun', 'Mar', 'Mie', 'Joi', 'Vin', 'Sâm', 'Dum'];

  String _dayLabel(DateTime d) {
    final now = StatsService.dayOnly(DateTime.now());
    final diff = d.difference(now).inDays;
    if (diff == 0) return 'Azi';
    if (diff == 1) return 'Mâine';
    if (diff == -1) return 'Ieri';
    return '${_weekdays[(d.weekday - 1) % 7]} ${d.day} ${_months[d.month - 1]}';
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
                  Text(s.emoji, style: TextStyle(fontSize: 22)),
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
                            style: TextStyle(
                                fontSize: 11, color: Silk.onSurfaceVar)),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle,
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
  final Exam? existing; // != null => editare
  final VoidCallback? onDelete;
  const _ExamSheet(
      {required this.initialDay,
      required this.initialStyle,
      this.existing,
      this.onDelete});
  @override
  State<_ExamSheet> createState() => _ExamSheetState();
}

class _ExamSheetState extends State<_ExamSheet> {
  late final _ctrl = TextEditingController(text: widget.existing?.name ?? '');
  late final _customCtrl =
      TextEditingController(text: widget.existing?.customLabel ?? '');
  late DateTime _date =
      widget.existing?.dateTime ?? widget.initialDay;
  late TimeOfDay _time = widget.existing != null
      ? TimeOfDay(
          hour: widget.existing!.dateTime.hour,
          minute: widget.existing!.dateTime.minute)
      : const TimeOfDay(hour: 9, minute: 0);

  late ExamKind _kind = widget.existing?.kind ?? ExamKind.examen;
  late ExamFormat _format = widget.existing?.format ?? ExamFormat.scris;
  late int _color = widget.existing?.colorValue ??
      kExamColors[math.Random().nextInt(kExamColors.length)];

  late bool _autoPlan = widget.existing?.hoursPerDay != null;
  late int _hoursPerDay = widget.existing?.hoursPerDay ?? 2;
  late DateTime _notifyFrom = widget.existing?.notifyFrom ??
      StatsService.dayOnly(DateTime.now());

  @override
  void dispose() {
    _ctrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(editing ? 'Editează examen' : 'Adaugă examen'),
            const SizedBox(height: 22),
            _lbl('MATERIE / NUME'),
            const SizedBox(height: 8),
            NeuInset(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(
                    border: InputBorder.none, hintText: 'ex. Analiză Matematică'),
              ),
            ),
            const SizedBox(height: 18),
            // tip
            _lbl('TIP'),
            const SizedBox(height: 8),
            Row(
              children: ExamKind.values
                  .map((k) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _pill(k.label, _kind == k,
                              () => setState(() => _kind = k)),
                        ),
                      ))
                  .toList(),
            ),
            if (_kind == ExamKind.altele) ...[
              const SizedBox(height: 8),
              NeuInset(
                radius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: TextField(
                  controller: _customCtrl,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Scrie tu (ex. Prezentare, Laborator...)'),
                ),
              ),
            ],
            const SizedBox(height: 14),
            // forma
            _lbl('FORMĂ'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _pill('Scris', _format == ExamFormat.scris,
                      () => setState(() => _format = ExamFormat.scris)),
                )),
                Expanded(
                    child: _pill('Oral', _format == ExamFormat.oral,
                        () => setState(() => _format = ExamFormat.oral))),
              ],
            ),
            const SizedBox(height: 14),
            // culoare
            Row(
              children: [
                _lbl('CULOARE'),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _color = kExamColors[
                      math.Random().nextInt(kExamColors.length)]),
                  child: Row(children: [
                    const Icon(Icons.shuffle_rounded,
                        size: 16, color: Silk.primary),
                    const SizedBox(width: 4),
                    Text('Random',
                        style: TextStyle(
                            fontSize: 12,
                            color: Silk.primary,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kExamColors.map((c) {
                final sel = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: sel
                          ? Border.all(color: Silk.onSurface, width: 3)
                          : null,
                    ),
                    child: sel
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
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
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (p != null) setState(() => _date = p);
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
            // plan de invatat (ore/zi)
            Neu(
              small: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Fă-mi un plan de învățat',
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
                    Divider(color: Silk.divider),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('Ore pe zi:',
                            style: TextStyle(color: Silk.onSurfaceVar)),
                        const Spacer(),
                        NeuButton(
                          padding: const EdgeInsets.all(8),
                          radius: 10,
                          onTap: () => setState(() =>
                              _hoursPerDay = (_hoursPerDay - 1).clamp(1, 16)),
                          child: Icon(Icons.remove,
                              color: Silk.primary, size: 16),
                        ),
                        SizedBox(
                            width: 48,
                            child: Text('${_hoursPerDay}h',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800))),
                        NeuButton(
                          padding: const EdgeInsets.all(8),
                          radius: 10,
                          onTap: () => setState(() =>
                              _hoursPerDay = (_hoursPerDay + 1).clamp(1, 16)),
                          child: Icon(Icons.add,
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
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: _date,
                        );
                        if (p != null) {
                          setState(
                              () => _notifyFrom = StatsService.dayOnly(p));
                        }
                      },
                      child: _field('ÎNCEP SĂ ÎNVĂȚ DIN',
                          '${_notifyFrom.day}.${_notifyFrom.month}.${_notifyFrom.year}'),
                    ),
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
                final custom = _customCtrl.text.trim();
                Navigator.of(context).pop(Exam(
                  id: widget.existing?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name,
                  dateTime: dt,
                  kind: _kind,
                  format: _format,
                  customLabel: custom.isEmpty ? null : custom,
                  notifyFrom: _notifyFrom,
                  hoursPerDay: _autoPlan ? _hoursPerDay : null,
                  studyStyle: widget.initialStyle,
                  result: widget.existing?.result ?? ExamResult.pending,
                  colorValue: _color,
                ));
              },
              child: Text(editing ? 'Salvează modificările' : 'Salvează examenul',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            if (editing && widget.onDelete != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onDelete!();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: const Text('🗑️  Șterge examenul',
                      style: TextStyle(
                          color: Color(0xFFE5484D),
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lbl(String t) => Text(t,
      style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
          color: Silk.onSurfaceVar));

  Widget _pill(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Silk.primary : Silk.bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? null : Silk.raisedSoft(),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? Colors.white : Silk.onSurfaceVar)),
        ),
      );

  Widget _field(String label, String value) => Neu(
        small: true,
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: Silk.onSurfaceVar)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(fontWeight: FontWeight.w700)),
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
            SheetHeader('Task — ${widget.dayLabel}'),
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
                              style: TextStyle(
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
                      Expanded(
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
                    Divider(color: Silk.divider),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NeuButton(
                          padding: const EdgeInsets.all(10),
                          radius: 12,
                          onTap: () => setState(
                              () => _target = (_target - 5).clamp(1, 100000)),
                          child: Icon(Icons.remove,
                              color: Silk.primary, size: 18),
                        ),
                        SizedBox(
                            width: 70,
                            child: Text('$_target',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800))),
                        NeuButton(
                          padding: const EdgeInsets.all(10),
                          radius: 12,
                          onTap: () => setState(
                              () => _target = (_target + 5).clamp(1, 100000)),
                          child: Icon(Icons.add,
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
                  child: Icon(Icons.remove, color: Silk.primary),
                ),
                SizedBox(
                  width: 110,
                  child: Text(_minutes == 0 ? 'fără' : _fmt(_minutes),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                NeuButton(
                  padding: const EdgeInsets.all(12),
                  radius: 14,
                  onTap: () =>
                      setState(() => _minutes = (_minutes + 15).clamp(0, 1440)),
                  child: Icon(Icons.add, color: Silk.primary),
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
              child: Text('Adaugă în plan',
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
}

