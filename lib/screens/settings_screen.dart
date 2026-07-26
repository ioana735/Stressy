import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/tracker_provider.dart';
import '../theme/silk.dart';

/// Pagina de setari (deschisa din rotita de pe Dashboard, cu buton de inapoi).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // urmarim darkMode ca tot Scaffold-ul (inclusiv fundalul) sa se reconstruiasca
    // imediat ce comuti modul intunecat din aceasta pagina
    final dark = ref.watch(
        trackerControllerProvider.select((s) => s.settings.darkMode));
    Silk.dark = dark;
    return Scaffold(
      backgroundColor: Silk.bg,
      appBar: AppBar(
        backgroundColor: Silk.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Silk.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Setări',
            style: TextStyle(
                color: Silk.onSurface, fontWeight: FontWeight.w800)),
      ),
      body: const SafeArea(child: SettingsView()),
    );
  }
}

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackerControllerProvider);
    final ctrl = ref.read(trackerControllerProvider.notifier);
    final s = state.settings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
      children: [
        Text('Gestionează obiectivele și reminderele zilnice.',
            style: TextStyle(color: Silk.onSurfaceVar)),
        const SizedBox(height: 20),

        // --- Aspect ---
        _Label(icon: Icons.dark_mode_outlined, text: 'ASPECT'),
        const SizedBox(height: 10),
        Neu(
          child: Row(
            children: [
              Icon(s.darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: Silk.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Mod întunecat',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Silk.onSurface)),
              ),
              Switch(
                value: s.darkMode,
                activeThumbColor: Colors.white,
                activeTrackColor: Silk.primary,
                onChanged: (v) =>
                    ctrl.updateSettings(s.copyWith(darkMode: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Obiectiv ---
        _Label(icon: Icons.timer_outlined, text: 'OBIECTIV ZILNIC'),
        const SizedBox(height: 10),
        Neu(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_goalLabel(s.dailyGoalMinutes),
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Silk.primary)),
                  Row(children: [
                    NeuButton(
                      padding: const EdgeInsets.all(12),
                      radius: 14,
                      onTap: () => ctrl.updateSettings(s.copyWith(
                          dailyGoalMinutes:
                              (s.dailyGoalMinutes - 30).clamp(30, 1440))),
                      child: Icon(Icons.remove,
                          color: Silk.onSurfaceVar, size: 20),
                    ),
                    const SizedBox(width: 10),
                    NeuButton(
                      padding: const EdgeInsets.all(12),
                      radius: 14,
                      onTap: () => ctrl.updateSettings(s.copyWith(
                          dailyGoalMinutes:
                              (s.dailyGoalMinutes + 30).clamp(30, 1440))),
                      child: Icon(Icons.add,
                          color: Silk.primary, size: 20),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  'Un obiectiv realist te ajută să menții focusul fără burnout.',
                  style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Silk.onSurfaceVar)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Mod note ---
        _Label(icon: Icons.grade_outlined, text: 'MOD NOTE'),
        const SizedBox(height: 10),
        Neu(
          child: Row(
            children: [
              Expanded(
                child: _pill('Liceu', !s.universityGrades,
                    () => ctrl.updateSettings(
                        s.copyWith(universityGrades: false))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pill('Facultate', s.universityGrades,
                    () => ctrl.updateSettings(
                        s.copyWith(universityGrades: true))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Remindere ---
        _Label(icon: Icons.notifications_none_rounded, text: 'REMINDERE'),
        const SizedBox(height: 10),
        Neu(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Orele la care vrei notificări',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Silk.onSurface)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 18, minute: 0),
                      );
                      if (picked != null) {
                        final t = picked.hour * 60 + picked.minute;
                        if (!s.reminderTimes.contains(t)) {
                          final list = [...s.reminderTimes, t]..sort();
                          ctrl.updateSettings(s.copyWith(reminderTimes: list));
                        }
                      }
                    },
                    child: Row(children: [
                      const Icon(Icons.add_circle,
                          color: Silk.primary, size: 20),
                      const SizedBox(width: 4),
                      Text('Adaugă',
                          style: TextStyle(
                              color: Silk.primary,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  'Primești câte o notificare în fiecare zi, la orele alese. Poți pune câte vrei.',
                  style: TextStyle(fontSize: 12, color: Silk.onSurfaceVar)),
              const SizedBox(height: 12),
              if (s.reminderTimes.isEmpty)
                Text('Nicio oră — apasă „Adaugă".',
                    style: TextStyle(color: Silk.onSurfaceVar))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: s.reminderTimes
                      .map((t) => GestureDetector(
                            onTap: () {
                              final list = [...s.reminderTimes]..remove(t);
                              ctrl.updateSettings(
                                  s.copyWith(reminderTimes: list));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Silk.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Silk.primary, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🕐 ${_fmt(t ~/ 60, t % 60)}',
                                      style: TextStyle(
                                          color: Silk.primary,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.close,
                                      size: 14, color: Silk.primary),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              Divider(color: Silk.divider, height: 24),
              _ToggleRow(
                title: 'Avertizare streak',
                subtitle: 'Când streak-ul e pe cale să expire (21:30)',
                value: s.streakWarning,
                onChanged: (on) =>
                    ctrl.updateSettings(s.copyWith(streakWarning: on)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        NeuButton(
          onTap: () async {
            await ctrl.testNotification();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(kIsWeb
                    ? 'Pe web notificările nu apar — testează pe telefon.'
                    : '🔔 Trimisă acum + una în 10 secunde (poți închide app-ul).'),
              ));
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_active_outlined,
                  color: Silk.primary, size: 20),
              SizedBox(width: 10),
              Text('Test notificare',
                  style: TextStyle(
                      color: Silk.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '⚠️ Reminderele funcționează doar pe telefon (Android/iOS), nu pe web.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Silk.onSurfaceVar),
        ),
        const SizedBox(height: 24),

        // --- Backup ---
        _Label(icon: Icons.backup_outlined, text: 'BACKUP DATE'),
        const SizedBox(height: 10),
        Neu(
          child: Column(
            children: [
              Text(
                  'Salvează un backup înainte să ștergi/reinstalezi aplicația. Datele nu se sincronizează automat.',
                  style: TextStyle(fontSize: 12, color: Silk.onSurfaceVar)),
              const SizedBox(height: 12),
              NeuButton(
                onTap: () => _exportBackup(context, ctrl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_rounded, color: Silk.primary, size: 20),
                    SizedBox(width: 10),
                    Text('Exportă datele',
                        style: TextStyle(
                            color: Silk.primary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              NeuButton(
                onTap: () => _importBackup(context, ctrl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download_rounded,
                        color: Silk.violet, size: 20),
                    SizedBox(width: 10),
                    Text('Importă datele',
                        style: TextStyle(
                            color: Silk.violet, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportBackup(BuildContext context, TrackerController ctrl) async {
    final data = ctrl.exportData();
    await Clipboard.setData(ClipboardData(text: data));
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Silk.bg,
        title: Text('Backup copiat ✅'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Am copiat backup-ul în clipboard. Lipește-l undeva sigur (Notițe, email, mesaj către tine). Ca să restaurezi, apeși „Importă datele" și lipești textul.',
                  style: TextStyle(fontSize: 13, color: Silk.onSurface)),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Silk.inset,
                    borderRadius: BorderRadius.circular(10)),
                child: SingleChildScrollView(
                  child: SelectableText(data,
                      style: TextStyle(fontSize: 10, color: Silk.onSurface)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Gata')),
        ],
      ),
    );
  }

  Future<void> _importBackup(BuildContext context, TrackerController ctrl) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Silk.bg,
        title: Text('Importă backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Lipește aici backup-ul salvat. ⚠️ Va înlocui datele actuale.',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            NeuInset(
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                    border: InputBorder.none, hintText: 'Lipește backup-ul...'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Anulează')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Importă')),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await ctrl.importData(controller.text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(ok
            ? 'Datele au fost restaurate! 🎉'
            : 'Backup invalid — verifică textul.'),
      ));
    }
  }

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  String _goalLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}

Widget _pill(String label, bool selected, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Silk.primary : Silk.bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected ? null : Silk.raisedSoft(),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : Silk.onSurfaceVar)),
      ),
    );

class _Label extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Label({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: Silk.primary),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w800,
                  color: Silk.onSurfaceVar)),
        ],
      );
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Silk.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: Silk.onSurfaceVar)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: Silk.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
