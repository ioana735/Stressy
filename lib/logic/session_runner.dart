import 'dart:async';

enum SessionPhase { work, breakTime }

/// Motor de sesiune de studiu. Suporta:
///  - numaratoare inversa (timer) pana la un target de lucru, SAU
///  - cronometru care numara in sus (stopwatch),
///  - pauze optionale (Pomodoro): dupa [workBlockSeconds] de lucru urmeaza
///    [breakBlockSeconds] de pauza, repetat.
///
/// Doar timpul de LUCRU se contorizeaza ca studiu (pauzele nu conteaza).
class SessionRunner {
  final bool stopwatch;
  final int targetWorkSeconds; // pentru timer; ignorat la stopwatch
  final bool breaksEnabled;
  final int workBlockSeconds;
  final int breakBlockSeconds;

  /// (faza curenta, secundele de afisat pentru faza curenta).
  final void Function(SessionPhase phase, int displaySeconds) onTick;

  /// Sesiune terminata natural (target de lucru atins). Da minutele lucrate.
  final void Function(int workedMinutes) onFinish;

  /// Se schimba faza (lucru <-> pauza).
  final void Function(SessionPhase newPhase)? onPhaseChange;

  Timer? _t;
  int _workedSec = 0;
  int _phaseElapsed = 0;
  SessionPhase _phase = SessionPhase.work;

  SessionRunner({
    required this.stopwatch,
    required this.targetWorkSeconds,
    required this.breaksEnabled,
    required this.workBlockSeconds,
    required this.breakBlockSeconds,
    required this.onTick,
    required this.onFinish,
    this.onPhaseChange,
  });

  int get workedMinutes => (_workedSec / 60).round();
  int get workedSeconds => _workedSec;
  SessionPhase get phase => _phase;

  void start() {
    _emit();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _step());
  }

  void _step() {
    if (_phase == SessionPhase.work) {
      _workedSec++;
      _phaseElapsed++;
      if (!stopwatch && _workedSec >= targetWorkSeconds) {
        _t?.cancel();
        onFinish(workedMinutes);
        return;
      }
      if (breaksEnabled && _phaseElapsed >= workBlockSeconds) {
        _phase = SessionPhase.breakTime;
        _phaseElapsed = 0;
        onPhaseChange?.call(_phase);
      }
    } else {
      _phaseElapsed++;
      if (_phaseElapsed >= breakBlockSeconds) {
        _phase = SessionPhase.work;
        _phaseElapsed = 0;
        onPhaseChange?.call(_phase); // pauza s-a incheiat
      }
    }
    _emit();
  }

  void _emit() {
    int display;
    if (_phase == SessionPhase.breakTime) {
      display = breakBlockSeconds - _phaseElapsed;
    } else if (stopwatch) {
      display = _workedSec; // numara in sus
    } else {
      display = targetWorkSeconds - _workedSec; // ramas
    }
    onTick(_phase, display < 0 ? 0 : display);
  }

  void stop() => _t?.cancel();
  void dispose() => _t?.cancel();

  static String fmt(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }
}
