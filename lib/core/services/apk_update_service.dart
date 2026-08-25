import 'dart:developer';
import 'dart:io';
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

  /// Downloads the APK from [downloadUrl], reporting progress via [onProgress].
  /// Supports optional cancellation via [cancelToken].
  Future<void> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/update.apk';
    final apkFile = File(savePath);

    try {
      // Clean up previous downloaded APK if present
      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      // Download with progress, throttled so we don't spam onProgress
      int lastReportedPercent = -1;

      await _dio.download(
        downloadUrl,
        savePath,
        cancelToken: cancelToken,
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
      // If error occurs, clean up partial download
      if (await apkFile.exists()) {
        try {
          await apkFile.delete();
        } catch (_) {}
      }
      if (e is DioException && CancelToken.isCancel(e)) {
        log('APK download was cancelled by user.');
        return;
      }
      log('APK download/install failed: $e');
      rethrow;
    }
  }
}
