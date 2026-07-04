import 'package:flutter/material.dart';

import '../models/planned_block.dart';
import '../theme/silk.dart';

/// Afiseaza un task planificat.
///  - Task cu TINTA cantitativa (pagini/seminarii): stepper manual +/-.
///  - Task cu TIMP estimat: progres AUTOMAT din minutele studiate azi la materie.
///  - Altfel: simplu de bifat manual.
class PlanBlockTile extends StatelessWidget {
  final PlannedBlock block;

  /// Minute studiate azi la materia acestui task (din sesiuni). Umple automat
  /// task-urile bazate pe timp.
  final int studiedMinutes;

  final VoidCallback onToggleDone;
  final ValueChanged<int> onUnitDelta;

  const PlanBlockTile({
    super.key,
    required this.block,
    required this.onToggleDone,
    required this.onUnitDelta,
    this.studiedMinutes = 0,
  });

  bool get _quantityMode => block.hasTarget;
  bool get _timeMode => !_quantityMode && block.plannedMinutes > 0;

  bool get _complete {
    if (block.done) return true;
    if (_quantityMode) return block.doneUnits >= block.targetUnits!;
    if (_timeMode) return studiedMinutes >= block.plannedMinutes;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final complete = _complete;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggleDone,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              complete ? Icons.check_circle : Icons.circle_outlined,
              color: complete ? Silk.success : Silk.onSurfaceVar,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      block.subject,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: complete ? Silk.onSurfaceVar : Silk.onSurface,
                        decoration:
                            complete ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  // dreapta: pentru task pe timp arata studiat/estimat
                  if (_timeMode)
                    Text('${_dur(studiedMinutes)} / ${_dur(block.plannedMinutes)}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: complete ? Silk.success : Silk.primary))
                  else if (block.plannedMinutes > 0)
                    Text(_dur(block.plannedMinutes),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Silk.onSurfaceVar)),
                ],
              ),
              if (block.note != null && block.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(block.note!,
                      style: const TextStyle(
                          fontSize: 12, color: Silk.onSurfaceVar)),
                ),

              // task pe TIMP -> bara de progres automata
              if (_timeMode) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (studiedMinutes / block.plannedMinutes)
                        .clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: const Color(0xFFDDE0E8),
                    valueColor: AlwaysStoppedAnimation(
                        complete ? Silk.success : Silk.primary),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('se umple automat când studiezi materia',
                      style: TextStyle(
                          fontSize: 10, color: Silk.onSurfaceVar)),
                ),
              ],

              // task cu TINTA cantitativa -> stepper manual
              if (_quantityMode) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StepBtn(
                        icon: Icons.remove, onTap: () => onUnitDelta(-1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${block.doneUnits}/${block.targetUnits} ${block.unitLabel ?? ""}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: complete ? Silk.success : Silk.primary),
                      ),
                    ),
                    _StepBtn(icon: Icons.add, onTap: () => onUnitDelta(1)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _dur(int m) {
    final h = m ~/ 60;
    final mm = m % 60;
    if (h > 0 && mm > 0) return '${h}h ${mm}m';
    if (h > 0) return '${h}h';
    return '${mm}m';
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Silk.bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: Silk.raisedSoft(),
          ),
          child: Icon(icon, size: 16, color: Silk.primary),
        ),
      );
}
