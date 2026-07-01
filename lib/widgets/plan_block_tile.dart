import 'package:flutter/material.dart';

import '../models/planned_block.dart';
import '../theme/silk.dart';

/// Afiseaza un task planificat: bifa + titlu + notita + tinta cantitativa
/// (ex. pagini) cu +/-. Fara bare de progres.
class PlanBlockTile extends StatelessWidget {
  final PlannedBlock block;
  final VoidCallback onToggleDone;
  final ValueChanged<int> onUnitDelta;
  final bool compact;

  const PlanBlockTile({
    super.key,
    required this.block,
    required this.onToggleDone,
    required this.onUnitDelta,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final complete = block.isComplete;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // bifa
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
        // continut
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
                  if (block.plannedMinutes > 0)
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
              // tinta cantitativa cu +/-
              if (block.hasTarget) ...[
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
