import 'package:flutter/material.dart';

import '../services/update_service.dart';
import '../utils/constants.dart';

/// Opens the "App Update" dialog: shows the installed version and lets the
/// user check GitHub Releases for a newer APK.
///
/// Kept deliberately simple (plain Material dialog, no glass/backdrop
/// layers) so it can be opened from any screen without rendering issues.
Future<void> showUpdateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _UpdateDialog(),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog();

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  String? _version;
  bool _checking = false;
  UpdateInfo? _available;

  @override
  void initState() {
    super.initState();
    UpdateService.currentVersion().then((v) {
      if (mounted) setState(() => _version = v.isEmpty ? '?' : v);
    });
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _available = null;
    });
    try {
      final info = await UpdateService.checkForUpdate();
      if (!mounted) return;
      if (info == null) {
        _toast('No update info yet. Check internet or no release published.');
      } else if (info.hasUpdate) {
        setState(() => _available = info);
      } else {
        _toast('Updated ka na! (v${info.currentVersion})');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _download() async {
    final info = _available;
    if (info == null) return;
    final ok = await UpdateService.launchUpdate(info);
    if (!ok && mounted) _toast('Dili ma-open ang download link.');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final update = _available;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('App Update')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            update == null
                ? (_version == null
                    ? 'Checking version...'
                    : 'Version v$_version')
                : 'v${update.currentVersion}  →  v${update.latestVersion}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (update == null) ...[
            const SizedBox(height: 6),
            Text(
              'Check for a newer release before downloading.',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            if (update.releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                update.releaseNotes.length > 300
                    ? '${update.releaseNotes.substring(0, 300)}...'
                    : update.releaseNotes,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(update == null ? 'Close' : 'Later'),
        ),
        if (update == null)
          FilledButton.icon(
            onPressed: _checking ? null : _check,
            icon: _checking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(_checking ? 'Checking' : 'Check for Updates'),
          )
        else
          FilledButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Update'),
          ),
      ],
    );
  }
}
