// lib/services/github_update_service.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Helper class for parsing and comparing semantic version strings numerically.
class AppVersion implements Comparable<AppVersion> {
  final int major;
  final int minor;
  final int patch;
  final int build;

  const AppVersion({
    this.major = 0,
    this.minor = 0,
    this.patch = 0,
    this.build = 0,
  });

  factory AppVersion.parse(String versionStr) {
    var clean = versionStr.trim().replaceFirst(RegExp(r'^[vV]'), '');

    int buildNum = 0;
    if (clean.contains('+')) {
      final parts = clean.split('+');
      clean = parts[0];
      if (parts.length > 1) {
        buildNum = int.tryParse(parts[1].replaceAll(RegExp(r'\D'), '')) ?? 0;
      }
    }

    if (clean.contains('-')) {
      clean = clean.split('-')[0];
    }

    final segments = clean.split('.');
    final major = segments.isNotEmpty ? (int.tryParse(segments[0]) ?? 0) : 0;
    final minor = segments.length > 1 ? (int.tryParse(segments[1]) ?? 0) : 0;
    final patch = segments.length > 2 ? (int.tryParse(segments[2]) ?? 0) : 0;

    return AppVersion(
      major: major,
      minor: minor,
      patch: patch,
      build: buildNum,
    );
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    return build.compareTo(other.build);
  }
}

class GitHubUpdateService {
  final Dio _dio;
  GitHubUpdateService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              headers: const {
                'User-Agent': 'Pitaka-App',
                'Accept': 'application/vnd.github+json',
              },
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  static const String _repoUrl =
      'https://api.github.com/repos/johndevss/pitaka/releases/latest';

  Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      // Get the version of the app currently running on the phone
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.buildNumber.isNotEmpty
          ? '${packageInfo.version}+${packageInfo.buildNumber}'
          : packageInfo.version;

      // Ask GitHub for the latest release
      final response = await _dio.get(_repoUrl);

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : {};

        final rawTag = data['tag_name']?.toString() ?? '';
        if (rawTag.isEmpty) return null;

        final latestVersion = rawTag.trim().replaceFirst(RegExp(r'^[vV]'), '');

        final assetsRaw = data['assets'];
        Map<String, dynamic>? apkAsset;

        if (assetsRaw is List) {
          for (final item in assetsRaw) {
            if (item is Map) {
              final asset = Map<String, dynamic>.from(item);
              final name = asset['name']?.toString() ?? '';
              if (name.endsWith('.apk')) {
                apkAsset = asset;
                break;
              }
            }
          }
        }

        if (apkAsset != null && isNewer(currentVersion, latestVersion)) {
          return {
            'latest_version': latestVersion,
            'download_url': apkAsset['browser_download_url']?.toString() ?? '',
            'release_notes':
                data['body']?.toString() ?? 'Minor bug fixes and improvements.',
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
    final currentVer = AppVersion.parse(current);
    final latestVer = AppVersion.parse(latest);
    return latestVer.compareTo(currentVer) > 0;
  }
}
