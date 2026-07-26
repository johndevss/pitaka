// lib/services/github_update_service.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GitHubUpdateService {
  final Dio _dio = Dio();

  // Replace with your actual GitHub username!
  static const String _repoUrl =
      'https://api.github.com/repos/johndevss/pitaka/releases/latest';

  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      // 1Get the version of the app currently running on the phone
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Ask GitHub for the latest release
      final response = await _dio.get(_repoUrl);

      if (response.statusCode == 200) {
        final data = response.data;

        // Remove 'v' if your tags are named like "v1.0.1"
        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');

        // Find the APK link in the release assets
        final assets = data['assets'] as List;
        final apkAsset = assets.firstWhere(
          (asset) => (asset['name'] as String).endsWith('.apk'),
          orElse: () => null,
        );

        // Compare versions
        if (apkAsset != null && _isNewer(currentVersion, latestVersion)) {
          return {
            'latest_version': latestVersion,
            'download_url': apkAsset['browser_download_url'],
            'release_notes':
                data['body'] ?? 'Minor bug fixes and improvements.',
          };
        }
      }
    } catch (e) {
      // If there's no internet or GitHub is down, just fail silently.
      // We don't want to crash the app just because it can't check for updates.
      log('Update check failed: $e');
    }
    return null;
  }

  // Simple check to see if GitHub's version string is higher than our current one
  bool _isNewer(String current, String latest) {
    return latest.compareTo(current) > 0;
  }
}
