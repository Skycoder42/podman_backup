import 'dart:io';

import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../adapters/process_adapter.dart';

// coverage:ignore-start
final uploadControllerProvider = Provider(
  (ref) => UploadController(
    ref.watch(processAdapterProvider),
  ),
);
// coverage:ignore-end

class UploadController {
  final ProcessAdapter _processAdapter;
  final _logger = Logger('$UploadController');

  UploadController(this._processAdapter);

  Future<void> upload({
    required String remoteHost,
    required Directory cacheDir,
  }) async {
    final fileCount = await cacheDir.list().length;
    _logger.info(
      'Uploading $fileCount backups from ${cacheDir.path} to $remoteHost',
    );
    await _processAdapter.run('rsync', [
      '--times',
      '--remove-source-files',
      '--human-readable',
      '--fsync',
      cacheDir.path,
      remoteHost,
    ]);
  }
}
