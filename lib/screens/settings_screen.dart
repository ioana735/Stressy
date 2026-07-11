import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/tracker_provider.dart';
import '../theme/silk.dart';

/// Pagina de setari (deschisa din rotita de pe Dashboard, cu buton de inapoi).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Silk.bg,
      appBar: AppBar(
        backgroundColor: Silk.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Silk.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Setări',
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
        const Text('Gestionează obiectivele și reminderele zilnice.',
            style: TextStyle(color: Silk.onSurfaceVar)),
        const SizedBox(height: 20),

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
                      style: const TextStyle(
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
                      child: const Icon(Icons.remove,
                          color: Silk.onSurfaceVar, size: 20),
                    ),
                    const SizedBox(width: 10),
                    NeuButton(
                      padding: const EdgeInsets.all(12),
                      radius: 14,
                      onTap: () => ctrl.updateSettings(s.copyWith(
                          dailyGoalMinutes:
                              (s.dailyGoalMinutes + 30).clamp(30, 1440))),
                      child: const Icon(Icons.add,
                          color: Silk.primary, size: 20),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                  'Un obiectiv realist te ajută să menții focusul fără burnout.',
                  style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Silk.onSurfaceVar)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Remindere ---
        _Label(icon: Icons.notifications_none_rounded, text: 'REMINDERE'),
        const SizedBox(height: 10),
        Neu(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            children: [
              _ToggleRow(
                title: 'Reminder zilnic',
                subtitle: s.hasDailyReminder
                    ? '🕐 ${_fmt(s.reminderHour!, s.reminderMinute!)}'
                    : 'Dezactivat',
                value: s.hasDailyReminder,
                onChanged: (on) => ctrl.updateSettings(on
                    ? s.copyWith(reminderHour: 18, reminderMinute: 0)
                    : s.copyWith(clearReminder: true)),
                onSubtitleTap: s.hasDailyReminder
                    ? () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                              hour: s.reminderHour!, minute: s.reminderMinute!),
                        );
                        if (picked != null) {
                          ctrl.updateSettings(s.copyWith(
                              reminderHour: picked.hour,
                              reminderMinute: picked.minute));
                        }
                      }
                    : null,
              ),
              const Divider(color: Color(0x11000000)),
              _ToggleRow(
                title: 'Memento de studiu',
                subtitle: 'Dacă n-am învățat încă (🕐 ${s.inactivityHour}:00)',
                value: s.inactivityReminder,
                onChanged: (on) =>
                    ctrl.updateSettings(s.copyWith(inactivityReminder: on)),
              ),
              const Divider(color: Color(0x11000000)),
              _ToggleRow(
                title: 'Avertizare streak',
                subtitle: 'Când streak-ul e pe cale să expire',
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                behavior: SnackBarBehavior.floating,
                content:
                    Text('Pe web notificările nu apar — testează pe telefon.'),
              ));
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
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
        const Text(
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
              const Text(
                  'Salvează un backup înainte să ștergi/reinstalezi aplicația. Datele nu se sincronizează automat.',
                  style: TextStyle(fontSize: 12, color: Silk.onSurfaceVar)),
              const SizedBox(height: 12),
              NeuButton(
                onTap: () => _exportBackup(context, ctrl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
                  children: const [
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
        title: const Text('Backup copiat ✅'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Am copiat backup-ul în clipboard. Lipește-l undeva sigur (Notițe, email, mesaj către tine). Ca să restaurezi, apeși „Importă datele" și lipești textul.',
                  style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFDFE2EA),
                    borderRadius: BorderRadius.circular(10)),
                child: SingleChildScrollView(
                  child: SelectableText(data,
                      style: const TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Gata')),
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
        title: const Text('Importă backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
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
              child: const Text('Anulează')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Importă')),
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
              style: const TextStyle(
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
  final VoidCallback? onSubtitleTap;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onSubtitleTap,
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
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Silk.onSurface)),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onSubtitleTap,
                  child: Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: onSubtitleTap != null
                              ? Silk.primary
                              : Silk.onSurfaceVar,
                          fontWeight: onSubtitleTap != null
                              ? FontWeight.w700
                              : FontWeight.w400)),
                ),
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
