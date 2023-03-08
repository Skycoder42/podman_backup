import 'package:riverpod/riverpod.dart';

import 'backup_strategy.dart';

// coverage:ignore-start
final backupControllerProvider = Provider(
  (ref) => BackupController(
    ref.watch(backupStrategyProvider),
  ),
);
// coverage:ignore-end

class BackupController {
  final BackupStrategy _backupStrategy;

  BackupController(this._backupStrategy);

  Future<void> backup() async {
    try {
      for (final service in _backupStrategy.services) {
        // TODO stop service
      }

      for (final volume in _backupStrategy.volumes) {
        // TODO perform backup
      }
    } finally {
      for (final service in _backupStrategy.services) {
        // TODO start service
      }
    }
  }
}
