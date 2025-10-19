import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';

import '../adapters/process_adapter.dart';

@injectable
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
      if (_logger.level <= Level.FINEST)
        '--verbose'
      else if (_logger.level <= Level.FINER)
        '--progress',
      '--recursive',
      '--copy-links',
      '--times',
      '--remove-source-files',
      '--human-readable',
      '${cacheDir.path}/',
      '$remoteHost/',
    ]);
  }
}
