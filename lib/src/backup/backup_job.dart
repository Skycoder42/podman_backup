import 'package:riverpod/riverpod.dart';

import '../cli/options.dart';
import 'backup_controller.dart';
import 'backup_strategy_builder.dart';

// coverage:ignore-start
final backupJobProvider = Provider(
  (ref) => BackupJob(
    ref.watch(backupStrategyBuilderProvider),
    ref.watch(backupControllerProvider),
  ),
);
// coverage:ignore-end

class BackupJob {
  final BackupStrategyBuilder _backupStrategyBuilder;
  final BackupController _backupController;

  BackupJob(
    this._backupStrategyBuilder,
    this._backupController,
  );

  Future<void> run(Options options) async {
    // steps:
    // - collect all volumes and the attached containers
    // - build backup strategy
    // - run backup for every pack
    //   - stop relevant containers
    //   - create backup
    //   - start relevant containers

    final strategy = await _backupStrategyBuilder.buildStrategy(
      backupLabel: options.backupLabel,
    );

    await _backupController.backup(strategy);
  }
}
