import 'package:injectable/injectable.dart';

import 'process_adapter.dart';

class BatchBuilder {
  final SftpAdapter _sftpAdapter;
  final String _remoteHost;
  final _commands = <String>[];

  BatchBuilder._(this._sftpAdapter, this._remoteHost);

  void ls({
    bool allFiles = false,
    bool withDetails = false,
    bool noEcho = false,
    bool ignoreResult = false,
  }) {
    _command(
      ['ls', if (withDetails) '-l' else '-1', if (allFiles) '-a'].join(' '),
      noEcho,
      ignoreResult,
    );
  }

  void rm(String path, {bool noEcho = false, bool ignoreResult = false}) =>
      _command("rm '$path'", noEcho, ignoreResult);

  Stream<String> execute() => _sftpAdapter._executeBatch(this);

  void _command(String command, bool noEcho, bool ignoreResult) {
    final cmdBuilder = StringBuffer();
    if (ignoreResult) {
      cmdBuilder.write('-');
    }
    if (noEcho) {
      cmdBuilder.write('@');
    }
    cmdBuilder.write(command);
    _commands.add(cmdBuilder.toString());
  }
}

@injectable
class SftpAdapter {
  final ProcessAdapter _processAdapter;

  const SftpAdapter(this._processAdapter);

  BatchBuilder batch(String remoteHost) => BatchBuilder._(this, remoteHost);

  Stream<String> _executeBatch(BatchBuilder batchBuilder) {
    if (batchBuilder._commands.isEmpty) {
      throw StateError('Cannot execute an empty batch');
    }

    return _processAdapter.streamLines('sftp', [
      '-b',
      '-',
      batchBuilder._remoteHost,
    ], stdinLines: Stream.fromIterable(batchBuilder._commands));
  }
}
