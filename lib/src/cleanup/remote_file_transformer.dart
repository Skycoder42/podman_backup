import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';

import '../models/remote_file_info.dart';

// coverage:ignore-start
final remoteFileTransformerProvider = Provider(
  (ref) => const RemoteFileTransformer(),
);
// coverage:ignore-end

class RemoteFileTransformer
    extends StreamTransformerBase<String, RemoteFileInfo> {
  const RemoteFileTransformer();

  @override
  Stream<RemoteFileInfo> bind(Stream<String> files) =>
      Stream.eventTransformed(files, RemoteFileTransformerSink.new);
}

@visibleForTesting
class RemoteFileTransformerSink implements EventSink<String> {
  static final _splitRegexp = RegExp(r'\s+');
  static final _backupRegexp = RegExp(
    r'^(.+)-(\d{4})_(\d{2})_(\d{2})_(\d{2})_(\d{2})_(\d{2})\.tar\.xz$',
  );

  final EventSink<RemoteFileInfo> _sink;

  const RemoteFileTransformerSink(this._sink);

  @override
  void add(String event) {
    try {
      _sink.add(_mapLine(event));
      // ignore: avoid_catches_without_on_clauses
    } catch (e, s) {
      _sink.addError(e, s);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _sink.addError(error, stackTrace);

  @override
  void close() => _sink.close();

  RemoteFileInfo _mapLine(String line) {
    final [
      _, // permissions,
      _, // links
      _, // owner
      _, // group
      sizeInBytes,
      _, // last modified month
      _, // last modified day
      _, // last modified year
      fileName,
      ...rest,
    ] = line.split(_splitRegexp);

    if (rest.isNotEmpty) {
      throw FormatException('Not a valid sftp "ls -l" line', line);
    }

    final (volume, backupDate) = _extractBackupInfo(fileName);
    return RemoteFileInfo(
      fileName: fileName,
      sizeInBytes: int.parse(sizeInBytes, radix: 10),
      volume: volume,
      backupDate: backupDate,
    );
  }

  (String, DateTime) _extractBackupInfo(String filename) {
    final match = _backupRegexp.matchAsPrefix(filename);
    if (match == null) {
      throw FormatException('Not a valid backup file name', filename);
    }

    return (
      match[1]!,
      DateTime.utc(
        int.parse(match[2]!, radix: 10),
        int.parse(match[3]!, radix: 10),
        int.parse(match[4]!, radix: 10),
        int.parse(match[5]!, radix: 10),
        int.parse(match[6]!, radix: 10),
        int.parse(match[7]!, radix: 10),
      ),
    );
  }
}
