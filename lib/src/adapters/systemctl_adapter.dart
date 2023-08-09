import 'package:riverpod/riverpod.dart';

import 'process_adapter.dart';

// coverage:ignore-start
final systemctlAdapterProvider = Provider(
  (ref) => SystemctlAdapter(
    ref.watch(processAdapterProvider),
  ),
);
// coverage:ignore-end

class SystemctlAdapter {
  final ProcessAdapter _processAdapter;

  bool runAsUser = true;

  SystemctlAdapter(this._processAdapter);

  Future<void> start(String unit) => _runSystemd(['start', unit]);

  Future<void> stop(String unit) => _runSystemd(['stop', unit]);

  Future<void> _runSystemd(List<String> args) => _processAdapter.run(
        'systemctl',
        [
          if (runAsUser) '--user',
          ...args,
        ],
      );
}
