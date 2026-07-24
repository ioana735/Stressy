import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logic/grades_service.dart';
import '../models/subject_grade.dart';
import '../state/tracker_provider.dart';
import '../theme/silk.dart';

class GradesView extends ConsumerStatefulWidget {
  const GradesView({super.key});
  @override
  ConsumerState<GradesView> createState() => _GradesViewState();
}

class _GradesViewState extends ConsumerState<GradesView> {
  (int, int)? _period; // null = toate
  bool _uni = false; // false = liceu, true = facultate

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(trackerControllerProvider).grades;
    final ctrl = ref.read(trackerControllerProvider.notifier);
    final periods = GradesService.periods(all);

    final filtered = _period == null
        ? all
        : all
            .where((g) => g.year == _period!.$1 && g.semester == _period!.$2)
            .toList();

    final arithmetic = GradesService.arithmetic(filtered);
    final weighted = GradesService.creditWeighted(filtered);
    final credits = GradesService.totalCredits(filtered);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Note',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Silk.onSurface)),
            GestureDetector(
              onTap: () => _openSheet(ctrl),
              child: const Row(children: [
                Icon(Icons.add_circle, color: Silk.primary, size: 22),
                SizedBox(width: 4),
                Text('Adaugă',
                    style: TextStyle(
                        color: Silk.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // toggle liceu / facultate
        Row(
          children: [
            Expanded(child: _modePill('Liceu', !_uni, () => setState(() => _uni = false))),
            const SizedBox(width: 10),
            Expanded(child: _modePill('Facultate', _uni, () => setState(() => _uni = true))),
          ],
        ),
        const SizedBox(height: 16),

        // selector an/semestru
        if (periods.isNotEmpty) ...[
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _periodPill('Toate', _period == null,
                    () => setState(() => _period = null)),
                ...periods.map((p) => _periodPill(
                    'An ${p.$1} · Sem ${p.$2}',
                    _period == p,
                    () => setState(() => _period = p))),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // card medie
        Neu(
          child: _uni
              ? Row(
                  children: [
                    Expanded(
                      child: _MediaBox(
                          label: 'Media aritmetică',
                          value: arithmetic,
                          color: Silk.primary),
                    ),
                    Container(
                        width: 1, height: 54, color: Silk.divider),
                    Expanded(
                      child: _MediaBox(
                          label: 'Ponderată (credite)',
                          value: weighted,
                          color: Silk.violet),
                    ),
                  ],
                )
              : _MediaBox(
                  label: 'Media generală',
                  value: arithmetic,
                  color: Silk.primary),
        ),
        if (_uni && credits > 0) ...[
          const SizedBox(height: 8),
          Center(
            child: Text('$credits credite',
                style:
                    TextStyle(fontSize: 12, color: Silk.onSurfaceVar)),
          ),
        ],
        const SizedBox(height: 20),

        if (filtered.isEmpty)
          Neu(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Adaugă prima materie cu nota ta.',
                    style: TextStyle(color: Silk.onSurfaceVar)),
              ),
            ),
          )
        else
          ...filtered.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey('grade_${g.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE5484D),
                        borderRadius: BorderRadius.circular(20)),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => ctrl.deleteGrade(g),
                  child: Neu(
                    small: true,
                    onTap: () => _openSheet(ctrl, edit: g),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.subject,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Silk.onSurface)),
                              Text(_subtitle(g),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Silk.onSurfaceVar)),
                            ],
                          ),
                        ),
                        Text(
                          g.finalGrade == null
                              ? '—'
                              : g.finalGrade!.toStringAsFixed(2),
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Silk.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  String _subtitle(SubjectGrade g) {
    final parts = <String>['An ${g.year} · Sem ${g.semester}'];
    if (g.credits > 0) parts.add('${g.credits} cr');
    if (g.simpleGrades.isNotEmpty) {
      parts.add(g.simpleGrades.map((e) => e.toStringAsFixed(
          e == e.roundToDouble() ? 0 : 2)).join(', '));
    } else if (g.components.isNotEmpty) {
      parts.add('${g.components.length} componente');
    }
    return parts.join(' · ');
  }

  Widget _modePill(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Silk.primary : Silk.bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected ? null : Silk.raisedSoft(),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Silk.onSurfaceVar)),
        ),
      );

  Widget _periodPill(String label, bool selected, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Silk.primary : Silk.bg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: selected ? null : Silk.raisedSoft(),
            ),
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? Colors.white : Silk.onSurfaceVar)),
          ),
        ),
      );

  Future<void> _openSheet(TrackerController ctrl, {SubjectGrade? edit}) async {
    final g = await showModalBottomSheet<SubjectGrade>(
      context: context,
      backgroundColor: Silk.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _GradeSheet(existing: edit, university: _uni),
    );
    if (g != null) ctrl.saveGrade(g);
  }
}

class _MediaBox extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;
  const _MediaBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value == null ? '—' : value!.toStringAsFixed(2),
            style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Silk.onSurfaceVar)),
      ],
    );
  }
}

// ------------------ sheet adaugare/editare nota ------------------

class _GradeSheet extends StatefulWidget {
  final SubjectGrade? existing;
  final bool university;
  const _GradeSheet({this.existing, required this.university});
  @override
  State<_GradeSheet> createState() => _GradeSheetState();
}

class _GradeSheetState extends State<_GradeSheet> {
  late final _subject =
      TextEditingController(text: widget.existing?.subject ?? '');
  late final _directCtrl = TextEditingController(
      text: widget.existing?.directGrade?.toString() ?? '');
  late int _year = widget.existing?.year ?? 1;
  late int _semester = widget.existing?.semester ?? 1;
  late int _credits = widget.existing?.credits ?? 0;
  late bool _useComponents = widget.existing?.components.isNotEmpty ?? false;

  // liceu: mai multe note simple
  late List<TextEditingController> _simple = (widget.existing?.simpleGrades ??
          const <double>[])
      .map((g) => TextEditingController(
          text: g.toStringAsFixed(g == g.roundToDouble() ? 0 : 2)))
      .toList();

  late List<_CompDraft> _comps = widget.existing?.components
          .map((c) => _CompDraft(c.name, c.grade.toString(), c.percent))
          .toList() ??
      [_CompDraft('Examen', '', 60), _CompDraft('Seminar', '', 40)];

  @override
  void initState() {
    super.initState();
    if (!widget.university && _simple.isEmpty) {
      _simple = [TextEditingController()];
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _directCtrl.dispose();
    for (final c in _simple) {
      c.dispose();
    }
    for (final c in _comps) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  void _submit() {
    final subject = _subject.text.trim();
    if (subject.isEmpty) return;

    if (!widget.university) {
      // liceu: note simple -> medie aritmetica
      final grades =
          _simple.map((c) => _parse(c.text)).whereType<double>().toList();
      Navigator.of(context).pop(SubjectGrade(
        id: widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        subject: subject,
        year: _year,
        semester: _semester,
        simpleGrades: grades,
      ));
      return;
    }

    // facultate
    List<GradeComponent> comps = [];
    double? direct;
    if (_useComponents) {
      for (final c in _comps) {
        final g = _parse(c.gradeCtrl.text);
        if (g != null) {
          comps.add(GradeComponent(
              name: c.nameCtrl.text.trim().isEmpty
                  ? 'Componentă'
                  : c.nameCtrl.text.trim(),
              grade: g,
              percent: c.percent));
        }
      }
    } else {
      direct = _parse(_directCtrl.text);
    }
    Navigator.of(context).pop(SubjectGrade(
      id: widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      subject: subject,
      year: _year,
      semester: _semester,
      credits: _credits,
      directGrade: _useComponents ? null : direct,
      components: _useComponents ? comps : const [],
    ));
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
            SheetHeader(editing ? 'Editează nota' : 'Adaugă notă'),
            const SizedBox(height: 20),
            _lbl('MATERIE'),
            const SizedBox(height: 8),
            NeuInset(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _subject,
                decoration: const InputDecoration(
                    border: InputBorder.none, hintText: 'ex. Matematică'),
              ),
            ),
            const SizedBox(height: 16),
            // an + semestru
            Row(
              children: [
                Expanded(
                    child: _stepper('An', _year,
                        (d) => setState(() => _year = (_year + d).clamp(1, 6)))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lbl('SEMESTRU'),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(child: _semPill(1)),
                        const SizedBox(width: 8),
                        Expanded(child: _semPill(2)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!widget.university)
              _liceuGrades()
            else
              _facultateGrades(),

            const SizedBox(height: 22),
            NeuButton(
              filled: true,
              onTap: _submit,
              child: Text(editing ? 'Salvează' : 'Adaugă nota',
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

  // --- liceu: lista de note simple ---
  Widget _liceuGrades() {
    return Neu(
      small: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notele la această materie',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Silk.onSurface)),
          const SizedBox(height: 4),
          Text('Media materiei = media aritmetică a notelor.',
              style: TextStyle(fontSize: 11, color: Silk.onSurfaceVar)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._simple.asMap().entries.map((e) => SizedBox(
                    width: 72,
                    child: Row(
                      children: [
                        Expanded(
                          child: NeuInset(
                            radius: 12,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            child: TextField(
                              controller: e.value,
                              textAlign: TextAlign.center,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  border: InputBorder.none, hintText: '—'),
                            ),
                          ),
                        ),
                        if (_simple.length > 1)
                          GestureDetector(
                            onTap: () => setState(
                                () => _simple.removeAt(e.key).dispose()),
                            child: Icon(Icons.close,
                                size: 14, color: Color(0xFFE5748A)),
                          ),
                      ],
                    ),
                  )),
              GestureDetector(
                onTap: () =>
                    setState(() => _simple.add(TextEditingController())),
                child: Container(
                  width: 44,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Silk.bg,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: Silk.raisedSoft(),
                  ),
                  child: Icon(Icons.add, color: Silk.primary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- facultate: credite + nota directa / componente ---
  Widget _facultateGrades() {
    final pctSum = _comps.fold(0, (s, c) => s + c.percent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepper('Credite', _credits,
            (d) => setState(() => _credits = (_credits + d).clamp(0, 60))),
        const SizedBox(height: 16),
        Neu(
          small: true,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Notă din componente (%)',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Silk.onSurface)),
                  ),
                  Switch(
                    value: _useComponents,
                    activeThumbColor: Colors.white,
                    activeTrackColor: Silk.primary,
                    onChanged: (v) => setState(() => _useComponents = v),
                  ),
                ],
              ),
              if (!_useComponents) ...[
                Divider(color: Silk.divider),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Nota:',
                        style: TextStyle(color: Silk.onSurfaceVar)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeuInset(
                        radius: 12,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        child: TextField(
                          controller: _directCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              border: InputBorder.none, hintText: 'ex. 9.50'),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Divider(color: Silk.divider),
                const SizedBox(height: 6),
                ..._comps.asMap().entries.map((e) => _compRow(e.key)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _comps.add(_CompDraft('', '', 0))),
                      icon: Icon(Icons.add, size: 18),
                      label: Text('Componentă'),
                    ),
                    Text('Total: $pctSum%',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: pctSum == 100
                                ? Silk.success
                                : const Color(0xFFE5748A))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _lbl(String t) => Text(t,
      style: TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
          color: Silk.onSurfaceVar));

  Widget _semPill(int s) {
    final sel = _semester == s;
    return GestureDetector(
      onTap: () => setState(() => _semester = s),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? Silk.primary : Silk.bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: sel ? null : Silk.raisedSoft(),
        ),
        child: Text('$s',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: sel ? Colors.white : Silk.onSurfaceVar)),
      ),
    );
  }

  Widget _stepper(String label, int value, ValueChanged<int> onDelta) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lbl(label.toUpperCase()),
        const SizedBox(height: 6),
        Row(
          children: [
            NeuButton(
              padding: const EdgeInsets.all(10),
              radius: 12,
              onTap: () => onDelta(-1),
              child: Icon(Icons.remove, color: Silk.primary, size: 18),
            ),
            Expanded(
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            NeuButton(
              padding: const EdgeInsets.all(10),
              radius: 12,
              onTap: () => onDelta(1),
              child: Icon(Icons.add, color: Silk.primary, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  Widget _compRow(int i) {
    final c = _comps[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: NeuInset(
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: TextField(
                controller: c.nameCtrl,
                decoration: const InputDecoration(
                    border: InputBorder.none, hintText: 'Nume'),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: NeuInset(
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: TextField(
                controller: c.gradeCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    border: InputBorder.none, hintText: 'Notă'),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    setState(() => c.percent = (c.percent - 5).clamp(0, 100)),
                child: Icon(Icons.remove, size: 16, color: Silk.primary),
              ),
              SizedBox(
                  width: 34,
                  child: Text('${c.percent}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700))),
              GestureDetector(
                onTap: () =>
                    setState(() => c.percent = (c.percent + 5).clamp(0, 100)),
                child: Icon(Icons.add, size: 16, color: Silk.primary),
              ),
            ],
          ),
          if (_comps.length > 1)
            GestureDetector(
              onTap: () => setState(() {
                _comps.removeAt(i).dispose();
              }),
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.close, size: 16, color: Color(0xFFE5748A)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Draft mutabil pentru o componenta in editor.
class _CompDraft {
  final TextEditingController nameCtrl;
  final TextEditingController gradeCtrl;
  int percent;
  _CompDraft(String name, String grade, this.percent)
      : nameCtrl = TextEditingController(text: name),
        gradeCtrl = TextEditingController(text: grade);
  void dispose() {
    nameCtrl.dispose();
    gradeCtrl.dispose();
  }
}
