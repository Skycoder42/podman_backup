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

    return BackupStrategy(_podmanAdapter, volumes);
  }
}
