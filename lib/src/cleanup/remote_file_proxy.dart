import 'package:riverpod/riverpod.dart';

import '../adapters/sftp_adapter.dart';
import '../models/remote_file_info.dart';
import 'remote_file_transformer.dart';

// coverage:ignore-start
final remoteFileProxyProvider = Provider(
  (ref) => RemoteFileProxy(
    ref.watch(sftpAdapterProvider),
    ref.watch(remoteFileTransformerProvider),
  ),
);
// coverage:ignore-end

class RemoteFileProxy {
  final SftpAdapter _sftpAdapter;
  final RemoteFileTransformer _remoteFileTransformer;

  RemoteFileProxy(this._sftpAdapter, this._remoteFileTransformer);

  Stream<RemoteFileInfo> listRemoteFiles(String remoteHost) =>
      (_sftpAdapter.batch(remoteHost)..ls(withDetails: true, noEcho: true))
          .execute()
          .transform(_remoteFileTransformer);

  Future<void> deleteFiles(
    String remoteHost,
    Iterable<RemoteFileInfo> filesToDelete,
  ) async {
    // delete the files
    final deleteBatch = _sftpAdapter.batch(remoteHost);
    for (final file in filesToDelete) {
      deleteBatch.rm(file.fileName, noEcho: true);
    }
    await deleteBatch.execute().drain();
  }
}
