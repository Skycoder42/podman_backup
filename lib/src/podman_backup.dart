import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';

import 'backup/backup_controller.dart';
import 'cleanup/cleanup_controller.dart';
import 'cli/options.dart';
import 'upload/upload_controller.dart';

@injectable
class PodmanBackup {
  final BackupController _backupController;
  final UploadController _uploadController;
  final CleanupController _cleanupController;
  final Options _options;
  final _logger = Logger('$PodmanBackup');

  PodmanBackup(
    this._backupController,
    this._uploadController,
    this._cleanupController,
    this._options,
  );

  Future<void> run() async {
    _logger.fine('Running systemctl in user mode: ${_options.user}');

    final backupCacheDir = await _options.backupCache.create(recursive: true);
    _logger.fine('Detected backup cache dir as: ${backupCacheDir.path}');

    if (_options.backupMode.backup) {
      _logger.info('>> Running backup');
      await _backupController.backup(
        backupLabel: _options.backupLabel,
        cacheDir: backupCacheDir,
      );
    }

    if (_options.backupMode.upload) {
      _logger.info('>> Running upload');
      await _uploadController.upload(
        remoteHost: _options.getRemoteHost(),
        cacheDir: backupCacheDir,
      );
    }

    if (_options.backupMode.cleanup) {
      _logger.info('>> Running cleanup');
      await _cleanupController.cleanupOldBackups(
        _options.getRemoteHost(),
        minKeep: _options.minKeep,
        maxKeep: _options.maxKeep,
        maxAge: _options.getMaxAge(),
        maxBytesTotal: _options.getMaxTotalSize(),
      );
    }
  }
}
