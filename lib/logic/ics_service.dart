import '../models/exam.dart';
import '../models/planned_block.dart';

/// Genereaza fisiere .ics (iCalendar) pentru examene si sesiuni de studiu.
/// iOS/Android Calendar le importa si dau notificari native.
class IcsService {
  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Format ora locala "floating" (fara Z) — Calendarul foloseste ora device-ului.
  static String _fmt(DateTime d) =>
      '${d.year}${_two(d.month)}${_two(d.day)}T${_two(d.hour)}${_two(d.minute)}${_two(d.second)}';

  static String _esc(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');

  static String _event({
    required String uid,
    required DateTime start,
    required DateTime end,
    required String summary,
    required String description,
    required DateTime stamp,
    Duration? alarmBefore,
  }) {
    final b = StringBuffer()
      ..writeln('BEGIN:VEVENT')
      ..writeln('UID:$uid@stressy')
      ..writeln('DTSTAMP:${_fmt(stamp)}')
      ..writeln('DTSTART:${_fmt(start)}')
      ..writeln('DTEND:${_fmt(end)}')
      ..writeln('SUMMARY:${_esc(summary)}')
      ..writeln('DESCRIPTION:${_esc(description)}');
    if (alarmBefore != null) {
      b
        ..writeln('BEGIN:VALARM')
        ..writeln('TRIGGER:-PT${alarmBefore.inMinutes}M')
        ..writeln('ACTION:DISPLAY')
        ..writeln('DESCRIPTION:${_esc(summary)}')
        ..writeln('END:VALARM');
    }
    b.writeln('END:VEVENT');
    return b.toString();
  }

  /// Calendar pentru un examen: evenimentul examenului (alarma 1 zi înainte)
  /// + cate un eveniment de studiu pentru fiecare bloc planificat al lui.
  static String examCalendar({
    required Exam exam,
    required List<PlannedBlock> blocks,
    required DateTime stamp,
    int reminderHour = 18,
  }) {
    final cal = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Stressy//RO')
      ..writeln('CALSCALE:GREGORIAN');

    // evenimentul examenului (1h implicit), alarma cu o zi inainte
    cal.write(_event(
      uid: 'exam_${exam.id}',
      start: exam.dateTime,
      end: exam.dateTime.add(const Duration(hours: 1)),
      summary: '${exam.kindLabel}: ${exam.name}',
      description: 'Examen (${exam.format.label}) — mult succes!',
      stamp: stamp,
      alarmBefore: const Duration(days: 1),
    ));

    // sesiunile de studiu (fiecare bloc, la ora reminderului)
    for (final b in blocks) {
      final start = DateTime(
          b.date.year, b.date.month, b.date.day, reminderHour, 0);
      final end = start.add(Duration(minutes: b.plannedMinutes));
      cal.write(_event(
        uid: 'block_${b.id}',
        start: start,
        end: end,
        summary: 'Studiază: ${b.subject}',
        description: 'Sesiune planificată pentru ${exam.name}.',
        stamp: stamp,
        alarmBefore: Duration.zero,
      ));
    }

    cal.writeln('END:VCALENDAR');
    return cal.toString();
  }
}
