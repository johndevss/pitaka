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
  /// [onProgress] (0.0 to 1.0), then opens the Android install prompt.
  Future<void> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress) onProgress,
  }) async {
    try {
      // 1. Find a safe place to store the file temporarily.
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/update.apk';

      // 2. Download with progress, throttled so we don't spam onProgress
      //    the way ota_update used to spam its native callbacks.
      int lastReportedPercent = -1;

      await _dio.download(
        downloadUrl,
        savePath,
        // persistentConnection: false works around a known Android/dio
        // issue where large downloads get cut with "Connection closed
        // while receiving data" partway through.
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

      // 3. Ask Android to open/install the downloaded file.
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
