import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  static const String _releasesApi =
      'https://api.github.com/repos/akhileshsavali18-beep/TPL-App/releases/latest';

  static const int _currentBuild =
      int.fromEnvironment('APP_BUILD_NUMBER', defaultValue: 1);

  bool _checking = false;

  Future<void> checkAndPrompt(BuildContext context) async {
    if (_checking || !Platform.isAndroid || !context.mounted) return;
    _checking = true;

    try {
      final response = await http.get(
        Uri.parse(_releasesApi),
        headers: const {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'TPL-Pro-App',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200 || !context.mounted) return;

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return;

      final tag = (data['tag_name'] ?? '').toString();
      final latestBuild = _extractBuildNumber(tag);
      if (latestBuild == null || latestBuild <= _currentBuild) return;

      final assets = data['assets'];
      if (assets is! List) return;

      String? apkUrl;
      for (final item in assets) {
        if (item is Map<String, dynamic> &&
            item['name'] == 'TPL-Pro-Release-APK.apk') {
          apkUrl = item['browser_download_url']?.toString();
          break;
        }
      }

      if (apkUrl == null || apkUrl.isEmpty || !context.mounted) return;

      await _showUpdateDialog(context, latestBuild, apkUrl);
    } catch (e) {
      debugPrint('App update check skipped: $e');
    } finally {
      _checking = false;
    }
  }

  int? _extractBuildNumber(String tag) {
    final match = RegExp(r'build\.(\d+)').firstMatch(tag);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  Future<void> _showUpdateDialog(
    BuildContext context,
    int latestBuild,
    String apkUrl,
  ) async {
    var downloading = false;
    var progress = 0.0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Update Available'),
              content: downloading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Downloading the latest TPL Pro update...'),
                        const SizedBox(height: 18),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 8),
                        Text('${(progress * 100).round()}%'),
                      ],
                    )
                  : Text(
                      'A newer TPL Pro version (build $latestBuild) is available. '
                      'Update now to get the latest features and fixes.',
                    ),
              actions: downloading
                  ? const []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Later'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          setState(() => downloading = true);
                          try {
                            final filePath = await _downloadApk(
                              apkUrl,
                              onProgress: (value) {
                                if (dialogContext.mounted) {
                                  setState(() => progress = value);
                                }
                              },
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();

                            final result = await OpenFilex.open(
                              filePath,
                              type: 'application/vnd.android.package-archive',
                            );

                            if (!result.type.toString().contains('done') &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not open the update installer: ${result.message}',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setState(() => downloading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Update failed: $e'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Update'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Future<String> _downloadApk(
    String url, {
    required void Function(double progress) onProgress,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/TPL-Pro-Update.apk');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }

      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();

      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            onProgress((received / total).clamp(0.0, 1.0));
          }
        }
      } finally {
        await sink.close();
      }

      onProgress(1.0);
      return file.path;
    } finally {
      client.close();
    }
  }
}
