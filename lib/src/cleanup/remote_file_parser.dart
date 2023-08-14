import 'package:riverpod/riverpod.dart';

import '../models/remote_file_info.dart';

// coverage:ignore-start
final remoteFileParserProvider = Provider(
  (ref) => RemoteFileParser(),
);
// coverage:ignore-end

class RemoteFileParser {
  static final _splitRegexp = RegExp(r'\s+');
  static final _backupRegexp =
      RegExp(r'.*-(\d{4})_(\d{2})_(\d{2})_(\d{2})_(\d{2})_(\d{2})$');

  Stream<RemoteFileInfo> parse(Stream<String> files) => files.map(_mapLsLine);

  RemoteFileInfo _mapLsLine(String line) {
    final [
      _, // permissions,
      _, // links
      _, // owner
      _, // group
      sizeInBytes,
      _, // last modified month
      _, // last modified day
      _, // last modified time
      fileName,
      ...rest,
    ] = line.split(_splitRegexp);

    if (rest.isNotEmpty) {
      throw FormatException('Not a valid sftp "ls -l" line', line);
    }

    return RemoteFileInfo(
      name: fileName,
      sizeInBytes: int.parse(sizeInBytes, radix: 10),
      backupDate: _extractBackupDate(fileName),
    );
  }

  DateTime _extractBackupDate(String filename) {
    final match = _backupRegexp.matchAsPrefix(filename);
    if (match == null) {
      throw FormatException('Not a valid backup file name', filename);
    }

    return DateTime.utc(
      int.parse(match[1]!, radix: 10),
      int.parse(match[2]!, radix: 10),
      int.parse(match[3]!, radix: 10),
      int.parse(match[4]!, radix: 10),
      int.parse(match[5]!, radix: 10),
      int.parse(match[6]!, radix: 10),
    );
  }
}
