import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data/notification_service.dart';
import 'data/storage_service.dart';
import 'screens/root_screen.dart';
import 'state/tracker_provider.dart';
import 'theme/silk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  final notifications = NotificationService();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        notificationProvider.overrideWithValue(notifications),
      ],
      child: const StressyApp(),
    ),
  );
}

class StressyApp extends ConsumerWidget {
  const StressyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(trackerControllerProvider).settings.darkMode;
    // seteaza paleta Silk inainte de a construi arborele
    Silk.dark = darkMode;

    final base = ThemeData(
      useMaterial3: true,
      brightness: darkMode ? Brightness.dark : Brightness.light,
      colorSchemeSeed: Silk.primary,
      scaffoldBackgroundColor: Silk.bg,
    );
    return MaterialApp(
      title: 'Stressy',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      ),
      home: const RootScreen(),
    );
  }
}
