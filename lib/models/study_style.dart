/// Stilul de invatare ales de user — influenteaza cum se distribuie planul.
enum StudyStyle {
  /// Distribuit uniform pe zile (invatare constanta, repetitie distribuita).
  spaced,

  /// Intensiv spre final — mai putin la inceput, tot mai mult aproape de examen.
  cramming,
}

extension StudyStyleX on StudyStyle {
  String get label => switch (this) {
        StudyStyle.spaced => 'Distribuit',
        StudyStyle.cramming => 'Intensiv',
      };

  String get description => switch (this) {
        StudyStyle.spaced =>
          'Cam la fel în fiecare zi — constant, cu revizuiri.',
        StudyStyle.cramming =>
          'Mai puțin la început, tot mai mult aproape de examen.',
      };

  String get emoji => switch (this) {
        StudyStyle.spaced => '🧩',
        StudyStyle.cramming => '🔥',
      };

  /// Greutatea zilei [i] din [n] zile (mai mare = mai multe minute).
  double weight(int i, int n) => switch (this) {
        StudyStyle.spaced => 1.0,
        StudyStyle.cramming => (i + 1).toDouble(), // ramp liniar crescator
      };
}
