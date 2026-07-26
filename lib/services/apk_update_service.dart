import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ApkUpdateService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 2),
    ),
  );

  /// Downloads the APK from [downloadUrl], reporting progress via
  Future<void> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress) onProgress,
  }) async {
    try {
      // Find a safe place to store the file temporarily.
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/update.apk';

      // Download with progress, throttled so we don't spam onProgress
      int lastReportedPercent = -1;

      await _dio.download(
        downloadUrl,
        savePath,
        options: Options(persistentConnection: false),
        onReceiveProgress: (received, total) {
          if (total <= 0) return; // total unknown, skip
          final percent = ((received / total) * 100).floor();

          // Only fire the callback when the percentage actually changes.
          if (percent != lastReportedPercent) {
            lastReportedPercent = percent;
            onProgress(received / total);
          }
        },
      );

      // Ask Android to open/install the downloaded file.
      final result = await OpenFilex.open(savePath);

      if (result.type != ResultType.done) {
        log('Could not open APK installer: ${result.message}');
      }
    } catch (e) {
      log('APK download/install failed: $e');
      rethrow;
    }
  }
}
