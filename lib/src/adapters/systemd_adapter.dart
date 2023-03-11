import 'package:riverpod/riverpod.dart';

import 'process_adapter.dart';

// coverage:ignore-start
final systemdAdapterProvider = Provider(
  (ref) => SystemdAdapter(
    ref.watch(processAdapterProvider),
  ),
);
// coverage:ignore-end

class SystemdAdapter {
  final ProcessAdapter _processAdapter;

  SystemdAdapter(this._processAdapter);

  Future<void> start(String unit) => _runSystemd(['start', unit]);

  Future<void> stop(String unit) => _runSystemd(['stop', unit]);

  Future<void> _runSystemd(List<String> args) => _processAdapter.run(
        'systemd',
        ['--user', ...args],
      );
}
