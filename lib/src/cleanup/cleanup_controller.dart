import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

import '../adapters/sftp_adapter.dart';
import 'remote_file_parser.dart';

// coverage:ignore-start
final cleanupControllerProvider = Provider(
  (ref) => CleanupController(
    ref.watch(sftpAdapterProvider),
    ref.watch(remoteFileParserProvider),
  ),
);
// coverage:ignore-end

class CleanupController {
  final SftpAdapter _sftpAdapter;
  final RemoteFileTransformer _remoteFileParser;

  final _logger = Logger('$CleanupController');

  CleanupController(this._sftpAdapter, this._remoteFileParser);

  Future<void> cleanupOldBackups(
    String remoteHost, {
    int? maxCount,
    Duration? maxAge,
    int? maxBytesTotal,
  }) async {
    if (maxCount == null && maxAge == null && maxBytesTotal == null) {
      _logger.warning('No cleanup filters specified. Skipping cleanup step.');
      return;
    }

    // list all remote files
    final remoteFiles = await (_sftpAdapter.batch(remoteHost)
          ..ls(withDetails: true, noEcho: true))
        .execute()
        .transform(_remoteFileParser)
        .toList();

    // apply count filter

    // apply age filter

    // apply size filter
  }
}
