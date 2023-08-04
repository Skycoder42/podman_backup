import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import 'backup/backup_controller.dart';
import 'cli/options.dart';
import 'upload/upload_controller.dart';

// coverage:ignore-start
final podmanBackupProvider = Provider(
  (ref) => PodmanBackup(
    ref.watch(backupControllerProvider),
    ref.watch(uploadControllerProvider),
  ),
);
// coverage:ignore-end

class PodmanBackup {
  final BackupController _backupController;
  final UploadController _uploadController;
  final _logger = Logger('$PodmanBackup');

  PodmanBackup(
    this._backupController,
    this._uploadController,
  );

  Future<void> run(Options options) async {
    final backupCacheDir = await options.backupCache.create(recursive: true);
    _logger.fine('Detected backup cache dir as: ${backupCacheDir.path}');

    if (options.backupMode.backup) {
      _logger.info('>> Running backup');
      await _backupController.backup(
        backupLabel: options.backupLabel,
        cacheDir: backupCacheDir,
        volumeHooks: options.getVolumeHooks(),
      );
    }

    if (options.backupMode.upload) {
      _logger.info('>> Running upload');
      await _uploadController.upload(
        remoteHost: options.getRemoteHost(),
        cacheDir: backupCacheDir,
      );
    }
  }
}
