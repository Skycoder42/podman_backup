import 'package:injectable/injectable.dart';

import '../cli/options.dart';
import 'process_adapter.dart';

@injectable
class SystemctlAdapter {
  final ProcessAdapter _processAdapter;
  final bool _runAsUser;

  SystemctlAdapter(this._processAdapter, Options options)
    : _runAsUser = options.user;

  Future<void> start(String unit) => _runSystemd(['start', unit]);

  Future<void> stop(String unit) => _runSystemd(['stop', unit]);

  Future<String> escape({required String template, required String value}) =>
      _processAdapter.streamLines('systemd-escape', [
        '--template',
        template,
        value,
      ]).single;

  Future<void> _runSystemd(List<String> args) =>
      _processAdapter.run('systemctl', [if (_runAsUser) '--user', ...args]);
}
