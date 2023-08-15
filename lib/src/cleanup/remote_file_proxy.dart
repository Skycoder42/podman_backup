import 'package:collection/collection.dart';
import 'package:riverpod/riverpod.dart';

import '../adapters/sftp_adapter.dart';
import '../models/remote_file_info.dart';
import 'map_values_x.dart';
import 'remote_file_parser.dart';

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

  Future<Map<String, Iterable<RemoteFileInfo>>> collectDeletableFiles(
    String remoteHost,
    int minKeep,
  ) async {
    if (minKeep < 1) {
      throw ArgumentError.value(
        minKeep,
        'minKeep',
        'Must keep at least one backup',
      );
    }

    // list all remote files
    final remoteFiles = await (_sftpAdapter.batch(remoteHost)
          ..ls(withDetails: true, noEcho: true))
        .execute()
        .transform(_remoteFileTransformer)
        .toList();

    // determine files that may be deleted
    return remoteFiles
        .groupListsBy(
          (info) => info.volume,
        )
        .forValues(
          (values) => values
              .sortedBy(
                (info) => info.backupDate,
              )
              .reversed
              .skip(minKeep),
        );
  }

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
