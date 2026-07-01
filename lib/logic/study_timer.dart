import 'dart:async';

/// Cronometru Pomodoro-style, complet decuplat de Flame si de UI.
/// Comunica prin callback-uri, deci poate fi testat independent.
class StudyTimer {
  final int sessionMinutes;
  final void Function() onStart;
  final void Function(int completedMinutes) onComplete;
  final void Function() onAbort;
  final void Function(Duration remaining)? onTick;

  Timer? _ticker;
  Duration _remaining = Duration.zero;

  StudyTimer({
    this.sessionMinutes = 25,
    required this.onStart,
    required this.onComplete,
    required this.onAbort,
    this.onTick,
  });

  Duration get remaining => _remaining;
  bool get isRunning => _ticker?.isActive ?? false;

  void start() {
    if (isRunning) return;
    _remaining = Duration(minutes: sessionMinutes);
    onStart();
    onTick?.call(_remaining);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _remaining -= const Duration(seconds: 1);
      onTick?.call(_remaining);
      if (_remaining.inSeconds <= 0) {
        _ticker?.cancel();
        onComplete(sessionMinutes);
      }
    });
  }

  /// Abandon manual: niciun fel de recompensa.
  void abort() {
    if (!isRunning) return;
    _ticker?.cancel();
    _remaining = Duration.zero;
    onAbort();
  }

  void dispose() => _ticker?.cancel();

  static String format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
