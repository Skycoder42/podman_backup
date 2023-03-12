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

  BackupStrategyBuilder(this._podmanAdapter);

  Future<BackupStrategy> buildStrategy({
    required String backupLabel,
  }) async {
    final volumes = await _podmanAdapter.volumeList(
      filters: {
        'label': backupLabel,
      },
    );

    final strategyData = <String, Set<String>>{};
    for (final volume in volumes) {
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

    return BackupStrategy(strategyData);
  }
}
