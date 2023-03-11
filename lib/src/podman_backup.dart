import 'dart:io';

import 'package:riverpod/riverpod.dart';

import 'backup/backup_controller.dart';
import 'cli/options.dart';

// coverage:ignore-start
final podmanBackupProvider = Provider(
  (ref) => PodmanBackup(
    ref.watch(backupControllerProvider),
  ),
);
// coverage:ignore-end

class PodmanBackup {
  final BackupController _backupController;

  PodmanBackup(
    this._backupController,
  );

  Future<void> run(Options options) async {
    final backupCacheDir = await _backupDir(options.backupCache);

    await _backupController.backup(
      backupLabel: options.backupLabel,
      cacheDir: backupCacheDir,
    );
  }

  Future<Directory> _backupDir(String? cacheDir) async {
    if (cacheDir != null) {
      return Directory(cacheDir).create();
    }

    final home = Platform.environment['HOME'];
    if (home != null) {
      return Directory('$home/.cache').create();
    }

    return Directory.systemTemp;
  }
}
