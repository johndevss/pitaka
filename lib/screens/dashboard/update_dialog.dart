import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/update_provider.dart';

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

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });

    final apkService = ref.read(apkUpdateServiceProvider);

    try {
      await apkService.downloadAndInstall(
        downloadUrl: widget.updateInfo['download_url'] as String,
        onProgress: (progress) {
          // setState during a download callback — safe here since
          // this widget is what's driving the download.
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );
      // Once OpenFilex.open() succeeds, Android takes over with its
      // own install screen, so we can close this dialog.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
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
