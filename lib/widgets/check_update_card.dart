import 'package:flutter/material.dart';

import '../services/update_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'glass_panel.dart';

/// "Check for Update" card shown in Profile screens.
///
/// - Shows current app version.
/// - Button calls GitHub Releases API.
/// - If newer version found -> dialog with Update button (opens APK link).
/// - If up-to-date / no release / offline -> snackbar message.
class CheckUpdateCard extends StatefulWidget {
  const CheckUpdateCard({super.key});

  @override
  State<CheckUpdateCard> createState() => _CheckUpdateCardState();
}

class _CheckUpdateCardState extends State<CheckUpdateCard> {
  bool _checking = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    UpdateService.currentVersion().then((v) {
      if (mounted) setState(() => _version = v);
    });
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;

      if (info == null) {
        _snack('No update info yet. Check internet or no release published.');
        return;
      }
      if (info.hasUpdate) {
        _showUpdateDialog(info);
      } else {
        _snack('Updated ka na! (v${info.currentVersion})');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showUpdateDialog(UpdateInfo info) {
    final p = AppTheme.paletteOf(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: AppGradients.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Bag-ong update available!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'v${info.currentVersion}  →  v${info.latestVersion}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: p.textPrimary,
              ),
            ),
            if (info.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                info.releaseNotes.length > 300
                    ? '${info.releaseNotes.substring(0, 300)}...'
                    : info.releaseNotes,
                style: TextStyle(fontSize: 13, color: p.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await UpdateService.launchUpdate(info);
              if (!ok && mounted) _snack('Dili ma-open ang download link.');
            },
            icon: const Icon(Icons.download_rounded),
            label: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return GlassPanel(
      radius: kCardRadius,
      blur: 26,
      strong: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Update',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _version.isEmpty
                      ? 'Checking version...'
                      : 'Version v$_version',
                  style: TextStyle(fontSize: 13, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _checking ? null : _check,
            child: _checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Check'),
          ),
        ],
      ),
    );
  }
}
