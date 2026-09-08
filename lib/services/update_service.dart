import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checks GitHub Releases for a newer app version.
///
/// How it works:
/// 1. Reads current installed version via package_info_plus (pubspec version).
/// 2. Calls GitHub API `releases/latest` for Crisjan0/NTC-A-Track.
/// 3. Compares tag (ex: `v1.0.1` -> `1.0.1`) vs current version.
///
/// For this to work, you must create a Release by pushing a tag:
///   git tag v1.0.1
///   git push origin v1.0.1
/// The `release-android.yml` workflow will auto-build the APK and attach it.
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String releaseUrl;
  final String? apkUrl;
  final bool hasUpdate;

  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.releaseUrl,
    required this.apkUrl,
    required this.hasUpdate,
  });
}

class UpdateService {
  UpdateService._();

  static const String _owner = 'Crisjan0';
  static const String _repo = 'NTC-A-Track';
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// Returns null when there is no published release yet, offline, or error.
  /// Throws no exception — UI decides what to show.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final current = _normalize(packageInfo.version);

      final res = await http
          .get(
            Uri.parse(_apiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 12));

      // No release published yet.
      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String? ?? '').trim();
      if (tag.isEmpty) return null;

      final latest = _normalize(tag);
      final notes = (json['body'] as String? ?? '').trim();
      final htmlUrl = (json['html_url'] as String? ?? '').trim();

      // Find the APK asset (uploaded by release workflow).
      String? apkUrl;
      final assets = json['assets'] as List<dynamic>?;
      if (assets != null) {
        for (final a in assets) {
          final name = (a['name'] as String? ?? '').toLowerCase();
          final url = a['browser_download_url'] as String?;
          if (url == null) continue;
          if (name.endsWith('.apk')) {
            apkUrl = url;
            break;
          }
        }
      }

      return UpdateInfo(
        currentVersion: current,
        latestVersion: latest,
        releaseNotes: notes,
        releaseUrl: htmlUrl,
        apkUrl: apkUrl,
        hasUpdate: _isNewer(latest, current),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> currentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '';
    }
  }

  /// Opens the APK download link (or release page fallback) in browser.
  /// Returns true if a URL was launched.
  static Future<bool> launchUpdate(UpdateInfo info) async {
    final target = (info.apkUrl?.isNotEmpty == true)
        ? info.apkUrl!
        : info.releaseUrl;
    if (target.isEmpty) return false;
    final uri = Uri.tryParse(target);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static String _normalize(String v) {
    var s = v.trim().toLowerCase();
    if (s.startsWith('v')) s = s.substring(1);
    // Drop build metadata: 1.0.0+1 -> 1.0.0
    final plus = s.indexOf('+');
    if (plus != -1) s = s.substring(0, plus);
    return s;
  }

  /// Simple semver compare: "1.0.10" > "1.0.2".
  static bool _isNewer(String latest, String current) {
    final l = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = l.length > c.length ? l.length : c.length;
    for (var i = 0; i < len; i++) {
      final lv = i < l.length ? l[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }
}
