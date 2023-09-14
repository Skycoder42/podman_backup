import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import 'adapters/systemctl_adapter.dart';
import 'backup/backup_controller.dart';
import 'cleanup/cleanup_controller.dart';
import 'cli/options.dart';
import 'upload/upload_controller.dart';

// coverage:ignore-start
final podmanBackupProvider = Provider(
  (ref) => PodmanBackup(
    ref.watch(systemctlAdapterProvider),
    ref.watch(backupControllerProvider),
    ref.watch(uploadControllerProvider),
    ref.watch(cleanupControllerProvider),
  ),
);
// coverage:ignore-end

class PodmanBackup {
  final SystemctlAdapter _systemctlAdapter;
  final BackupController _backupController;
  final UploadController _uploadController;
  final CleanupController _cleanupController;
  final _logger = Logger('$PodmanBackup');

  PodmanBackup(
    this._systemctlAdapter,
    this._backupController,
    this._uploadController,
    this._cleanupController,
  );

  Future<void> run(Options options) async {
    _logger.fine('Running systemctl in user mode: ${options.user}');
    _systemctlAdapter.runAsUser = options.user;

    final backupCacheDir = await options.backupCache.create(recursive: true);
    _logger.fine('Detected backup cache dir as: ${backupCacheDir.path}');

    if (options.backupMode.backup) {
      _logger.info('>> Running backup');
      await _backupController.backup(
        backupLabel: options.backupLabel,
        cacheDir: backupCacheDir,
      );
    }

    if (options.backupMode.upload) {
      _logger.info('>> Running upload');
      await _uploadController.upload(
        remoteHost: options.getRemoteHost(),
        cacheDir: backupCacheDir,
      );
    }

    if (options.backupMode.cleanup) {
      _logger.info('>> Running cleanup');
      await _cleanupController.cleanupOldBackups(
        options.getRemoteHost(),
        minKeep: options.minKeep,
        maxKeep: options.maxKeep,
        maxAge: options.getMaxAge(),
        maxBytesTotal: options.getMaxTotalSize(),
      );
    }
  }
}
