import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stressy/data/notification_service.dart';
import 'package:stressy/data/storage_service.dart';
import 'package:stressy/main.dart';
import 'package:stressy/state/tracker_provider.dart';

/// Teste de randare la dimensiuni de TELEFON. Orice overflow (ceva care iese
/// din ecran) e raportat ca eroare de framework si pica testul.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpApp(WidgetTester tester) async {
    // ecran de telefon (iPhone ~390x844)
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
    // demonteaza ca sa se anuleze timer-ul de decay
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('Dashboard se randează pe telefon', (tester) async {
    await pumpApp(tester);
    expect(find.text('Stressy'), findsWidgets);
    expect(find.text('ÎNCEPE SĂ ÎNVEȚI'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('NOTE'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Navigare prin toate tab-urile fără overflow', (tester) async {
    await pumpApp(tester);

    // Plan
    await tester.tap(find.text('PLAN'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Plan'), findsWidgets);
    expect(find.text('Examene'), findsOneWidget);

    // Note
    await tester.tap(find.text('NOTE'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Note'), findsWidgets);
    expect(find.text('Liceu'), findsOneWidget);
    expect(find.text('Facultate'), findsOneWidget);

    // Stats
    await tester.tap(find.text('STATS'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Statistici'), findsOneWidget);

    // Înapoi la Dashboard
    await tester.tap(find.text('DASHBOARD'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ÎNCEPE SĂ ÎNVEȚI'), findsOneWidget);

    await tearDownApp(tester);
  });

  testWidgets('Sheet-ul de sesiune se deschide pe telefon', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('ÎNCEPE SĂ ÎNVEȚI'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Sesiune de studiu'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Cronometru'), findsOneWidget);
    await tearDownApp(tester);
  });

  testWidgets('Sheet-ul de notă (liceu) se deschide', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('NOTE'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Adaugă'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Adaugă notă'), findsOneWidget);
    expect(find.text('Notele la această materie'), findsOneWidget);
    await tearDownApp(tester);
  });
}
