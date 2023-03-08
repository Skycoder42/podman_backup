import 'package:riverpod/riverpod.dart';

import '../cli/options.dart';
import 'volume_configuration_loader.dart';

// coverage:ignore-start
final backupJobProvider = Provider(
  (ref) => BackupJob(
    ref.watch(volumeConfigurationLoaderProvider),
  ),
);
// coverage:ignore-end

class BackupJob {
  final VolumeConfigurationLoader _volumeConfigurationLoader;

  BackupJob(this._volumeConfigurationLoader);

  Future<void> run(Options options) async {
    // steps:
    // - collect all volumes and the attached containers
    // - build backup strategy
    // - run backup for every pack
    //   - stop relevant containers
    //   - create backup
    //   - start relevant containers

    final configuration = await _volumeConfigurationLoader
        .loadVolumeConfigurations(options.backupLabel)
        .toList();

    // ignore: avoid_print
    print(configuration);
  }
}
