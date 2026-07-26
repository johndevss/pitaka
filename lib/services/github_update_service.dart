// lib/services/github_update_service.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class GitHubUpdateService {
  final Dio _dio;
  GitHubUpdateService({Dio? dio}) : _dio = dio ?? Dio();

  static const String _repoUrl =
      'https://api.github.com/repos/johndevss/pitaka/releases/latest';

  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      // Get the version of the app currently running on the phone
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Ask GitHub for the latest release
      final response = await _dio.get(_repoUrl);

      if (response.statusCode == 200) {
        final data = response.data;

        final latestVersion = (data['tag_name'] as String).replaceAll('v', '');

        final assets = (data['assets'] as List).cast<Map<String, dynamic>>();

        Map<String, dynamic>? apkAsset;
        for (final asset in assets) {
          if ((asset['name'] as String).endsWith('.apk')) {
            apkAsset = asset;
            break;
          }
        }

        if (apkAsset != null && isNewer(currentVersion, latestVersion)) {
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
      log('Update check failed: $e');
    }
    return null;
  }

  bool isNewer(String current, String latest) {
    return latest.compareTo(current) > 0;
  }
}
