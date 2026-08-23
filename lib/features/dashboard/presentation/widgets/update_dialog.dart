import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitaka/core/providers/update_provider.dart';

/// Shown when a new GitHub release is available.
/// Call with: showDialog(context: context, builder: (_) => UpdateDialog(updateInfo: info));
class UpdateDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _error;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel('Dialog closed');
    super.dispose();
  }

  Future<void> _startUpdate() async {
    _cancelToken = CancelToken();
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    final apkService = ref.read(apkUpdateServiceProvider);

    try {
      await apkService.downloadAndInstall(
        downloadUrl: widget.updateInfo['download_url'] as String,
        cancelToken: _cancelToken,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted && !(_cancelToken?.isCancelled ?? false)) {
        setState(() {
          _isDownloading = false;
          _error = 'Download failed. Check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestVersion = widget.updateInfo['latest_version'] as String;
    final releaseNotes = widget.updateInfo['release_notes'] as String;

    return AlertDialog(
      title: Text('Update available: v$latestVersion'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isDownloading) ...[
                Text(releaseNotes),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ] else ...[
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 12),
                Text('${(_progress * 100).toStringAsFixed(0)}%'),
              ],
            ],
          ),
        ),
      ),
      actions: _isDownloading
          ? [] // hide buttons while downloading
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: _startUpdate,
                child: const Text('Update'),
              ),
            ],
    );
  }
}
