// lib/providers/update_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/github_update_service.dart';
import '../services/apk_update_service.dart';

// Provides a single instance of the version-check service
final updateServiceProvider = Provider<GitHubUpdateService>((ref) {
  return GitHubUpdateService();
});

// Provides a single instance of the download/install service
final apkUpdateServiceProvider = Provider<ApkUpdateService>((ref) {
  return ApkUpdateService();
});

// A FutureProvider that automatically runs our check when watched by the UI
final updateCheckProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return await service.checkForUpdate();
});
