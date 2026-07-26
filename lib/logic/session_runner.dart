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

  // Bazat pe ceasul real (nu pe numarul de tick-uri), ca sa nu ramana in urma
  // cand iOS/Android incetinesc Timer-ul in fundal (ecran stins, app minimizat).
  int _workedSecBeforePhase = 0; // secunde de lucru acumulate in fazele anterioare
  DateTime _phaseStartAt = DateTime.now();
  SessionPhase _phase = SessionPhase.work;
  bool _finished = false;

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

  int get _phaseElapsed =>
      DateTime.now().difference(_phaseStartAt).inSeconds;

  int get workedSeconds => _phase == SessionPhase.work
      ? _workedSecBeforePhase + _phaseElapsed
      : _workedSecBeforePhase;
  int get workedMinutes => (workedSeconds / 60).round();
  SessionPhase get phase => _phase;

  void start() {
    _phaseStartAt = DateTime.now();
    _emit();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => _step());
  }

  void _step() {
    if (_finished) return;
    final elapsed = _phaseElapsed;
    if (_phase == SessionPhase.work) {
      final worked = _workedSecBeforePhase + elapsed;
      if (!stopwatch && worked >= targetWorkSeconds) {
        _finished = true;
        _t?.cancel();
        _workedSecBeforePhase = targetWorkSeconds;
        onFinish(workedMinutes);
        return;
      }
      if (breaksEnabled && elapsed >= workBlockSeconds) {
        _workedSecBeforePhase = worked;
        _phase = SessionPhase.breakTime;
        _phaseStartAt = DateTime.now();
        onPhaseChange?.call(_phase);
      }
    } else {
      if (elapsed >= breakBlockSeconds) {
        _phase = SessionPhase.work;
        _phaseStartAt = DateTime.now();
        onPhaseChange?.call(_phase); // pauza s-a incheiat
      }
    }
    _emit();
  }

  void _emit() {
    final elapsed = _phaseElapsed;
    int display;
    if (_phase == SessionPhase.breakTime) {
      display = breakBlockSeconds - elapsed;
    } else if (stopwatch) {
      display = _workedSecBeforePhase + elapsed; // numara in sus
    } else {
      display = targetWorkSeconds - (_workedSecBeforePhase + elapsed); // ramas
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
