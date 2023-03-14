import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../adapters/podman_adapter.dart';
import 'backup_strategy.dart';

// coverage:ignore-start
final backupStrategyBuilderProvider = Provider(
  (ref) => BackupStrategyBuilder(
    ref.watch(podmanAdapterProvider),
  ),
);
// coverage:ignore-end

class BackupStrategyBuilder {
  final PodmanAdapter _podmanAdapter;
  final _logger = Logger('$BackupStrategyBuilder');

  BackupStrategyBuilder(this._podmanAdapter);

  Future<BackupStrategy> buildStrategy({
    required String backupLabel,
  }) async {
    _logger.fine('Loading volumes with label $backupLabel');
    final volumes = await _podmanAdapter.volumeList(
      filters: {
        'label': backupLabel,
      },
    );

    final strategyData = <String, Set<String>>{};
    for (final volume in volumes) {
      _logger.fine('Loading attached services for volume $volume');
      final containers = await _podmanAdapter.ps(
        filters: {
          'volume': volume.name,
        },
      );

      strategyData[volume.name] = containers
          .map((c) => c.labels['PODMAN_SYSTEMD_UNIT'])
          .whereType<String>()
          .toSet();
    }

    _logger.fine('Building backup strategy');
    return BackupStrategy(strategyData);
  }
}
