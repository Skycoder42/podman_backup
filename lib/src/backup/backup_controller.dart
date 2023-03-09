import 'package:riverpod/riverpod.dart';

import 'backup_strategy.dart';

// coverage:ignore-start
final backupControllerProvider = Provider(
  (ref) => BackupController(),
);
// coverage:ignore-end

class BackupController {
  BackupController();

  Future<void> backup(BackupStrategy strategy) async {
    while (await strategy.next()) {
      await _backupStep(strategy);
    }
  }

  Future<void> _backupStep(BackupStrategy strategy) async {
    try {
      for (final service in strategy.services) {
        // TODO stop service
      }

      for (final volume in strategy.volumes) {
        // TODO perform backup
      }
    } finally {
      for (final service in strategy.services) {
        // TODO start service
      }
    }
  }
}
