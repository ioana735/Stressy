import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stressy/data/notification_service.dart';
import 'package:stressy/data/storage_service.dart';
import 'package:stressy/main.dart';
import 'package:stressy/state/tracker_provider.dart';

/// Teste end-to-end pentru fluxurile principale (Plan -> Note -> Stats),
/// inclusiv teste de regresie pentru bug-uri reparate recent:
///  - crash la "+ Adaugă" in fisa de note dintr-un examen (List.filled fix)
///  - salvare silentioasa esuata cand materia e goala (validare + mesaj)
///  - overflow-uri de layout (Setari, Plan, Note) descoperite prin acest test
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final notif = NotificationService();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        notificationProvider.overrideWithValue(notif),
      ],
      child: const StressyApp(),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tearDownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  Finder byHint(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint);

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  Future<void> setUniversityMode(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.text('Facultate'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets(
      'Examen adaugat in Plan apare grupat in Note, iar "+ Adauga" din fisa notei nu crapa (regresie)',
      (tester) async {
    await pumpApp(tester);
    await setUniversityMode(tester);

    // --- Plan: adauga un examen ---
    await tester.tap(find.text('PLAN'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Adaugă examen'));
    await tester.pumpAndSettle();
    // REGRESIE: fisa de examen (TIP/FORMĂ/Nota) nu trebuie sa dea overflow
    expect(tester.takeException(), isNull);

    await tester.enterText(byHint('ex. Analiză Matematică'), 'Analiză Test');
    await tester.pump();
    await tapVisible(tester, find.text('Salvează examenul'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Analiză Test'), findsWidgets);

    // --- Note: nota derivata din examen apare grupata ---
    await tester.tap(find.text('NOTE'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Analiză Test'), findsOneWidget);

    // deschide fisa notei (tap pe card)
    await tester.tap(find.text('Analiză Test'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Note —'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // REGRESIE: "+ Adauga" nu trebuie sa arunce nicio exceptie
    // (List.filled era fixed-length -> UnsupportedError la primul tap)
    // si pila Scris/Test/Altele nu trebuie sa dea overflow (fix cu Wrap)
    await tapVisible(tester, find.text('Adaugă'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.text('Adaugă'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // doua rânduri noi, cu categoria implicita "Scris" preselectata
    expect(find.text('Scris'), findsWidgets);

    // Salveaza fara sa completezi nimic in draft-uri -> nu trebuie sa crape
    await tapVisible(tester, find.text('Salvează'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tearDownApp(tester);
  });

  testWidgets(
      'Nota manuala fara materie completata arata eroare si nu se salveaza silentios',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('NOTE'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Notă manuală'));
    await tester.pumpAndSettle();

    // apasa direct Adauga, fara sa completeze Materia
    await tapVisible(tester, find.text('Adaugă nota'));
    await tester.pumpAndSettle();

    // sheet-ul ramane deschis (nu s-a inchis silentios) + mesaj de eroare
    expect(find.text('Adaugă notă'), findsOneWidget);
    expect(find.text('Completează materia ca să salvezi nota.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);

    await tearDownApp(tester);
  });

  testWidgets('Nota manuala cu materie completata se salveaza si apare in Note',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('NOTE'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Notă manuală'));
    await tester.pumpAndSettle();

    await tester.enterText(byHint('ex. Matematică'), 'Chimie');
    await tester.pump();
    // liceu implicit: completeaza prima nota simpla (are hint '—')
    await tester.enterText(byHint('—').first, '9');
    await tester.pump();

    await tapVisible(tester, find.text('Adaugă nota'));
    await tester.pumpAndSettle();

    expect(find.text('Chimie'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tearDownApp(tester);
  });
}
