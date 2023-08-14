import 'package:riverpod/riverpod.dart';

import 'process_adapter.dart';

// coverage:ignore-start
final sftpAdapterProvider = Provider(
  (ref) => SftpAdapter(
    ref.watch(processAdapterProvider),
  ),
);
// coverage:ignore-end

class BatchBuilder {
  final SftpAdapter _sftpAdapter;
  final _commands = <String>[];

  BatchBuilder._(this._sftpAdapter);

  void ls({
    bool allFiles = false,
    bool withDetails = false,
  }) {
    _commands.add(
      [
        'ls',
        if (withDetails) '-l' else '-1',
        if (allFiles) '-a',
      ].join(' '),
    );
  }

  void rm(String path) => _commands.add("rm '$path'");

  Future<void> execute() => _sftpAdapter._executeBatch(_commands);
}

class SftpAdapter {
  final ProcessAdapter _processAdapter;

  SftpAdapter(this._processAdapter);

  BatchBuilder batch() => BatchBuilder._(this);

  Future<void> _executeBatch(List<String> commands) async {}
}
