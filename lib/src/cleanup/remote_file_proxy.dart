import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';

import '../adapters/sftp_adapter.dart';
import '../models/remote_file_info.dart';
import 'remote_file_transformer.dart';

@injectable
class RemoteFileProxy {
  final SftpAdapter _sftpAdapter;
  final RemoteFileTransformer _remoteFileTransformer;
  final _logger = Logger('$RemoteFileProxy');

  RemoteFileProxy(this._sftpAdapter, this._remoteFileTransformer);

  Stream<RemoteFileInfo> listRemoteFiles(String remoteHost) {
    _logger.fine('Listing existing backups for $remoteHost');
    return (_sftpAdapter.batch(remoteHost)..ls(withDetails: true, noEcho: true))
        .execute()
        .transform(_remoteFileTransformer);
  }

  Future<void> deleteFiles(
    String remoteHost,
    Iterable<RemoteFileInfo> filesToDelete,
  ) async {
    _logger.fine('Deleting files on $remoteHost');
    // delete the files
    final deleteBatch = _sftpAdapter.batch(remoteHost);
    for (final file in filesToDelete) {
      _logger.finest('- ${file.fileName}');
      deleteBatch.rm(file.fileName, noEcho: true);
    }

    await deleteBatch.execute().drain<void>();
  }
}
