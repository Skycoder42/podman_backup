import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';
import 'package:rxdart/transformers.dart';

import '../models/remote_file_info.dart';
import 'map_values_x.dart';

// coverage:ignore-start
final cleanupFilterProvider = Provider(
  (ref) => CleanupFilter(),
);
// coverage:ignore-end

typedef _InfoMap = Map<String, Iterable<RemoteFileInfo>>;

class CleanupFilter {
  final _logger = Logger('$CleanupFilter');

  Future<Set<RemoteFileInfo>> collectDeletableFiles(
    Stream<RemoteFileInfo> remoteFiles, {
    required int minKeep,
    int? maxKeep,
    Duration? maxAge,
    int? maxBytesTotal,
  }) async {
    if (minKeep < 1) {
      throw ArgumentError.value(
        minKeep,
        'minKeep',
        'Must keep at least one backup',
      );
    }

    if (maxKeep == null && maxAge == null && maxBytesTotal == null) {
      _logger.warning('No cleanup filters specified. Skipping cleanup step.');
      return const {};
    }

    final filesAllowedToBeDeleted = await _collectDeletableFiles(
      remoteFiles,
      minKeep,
    );
    var filesToKeep = filesAllowedToBeDeleted;

    // apply count filter
    if (maxKeep != null) {
      filesToKeep = _filterCount(filesToKeep, minKeep, maxKeep);
    }

    // apply age filter
    if (maxAge != null) {
      filesToKeep = _filterAge(filesToKeep, maxAge);
    }

    // apply size filter
    var allFilesToKeep = filesToKeep.values.expand((infos) => infos);
    if (maxBytesTotal != null) {
      allFilesToKeep = _filterSize(allFilesToKeep, maxBytesTotal);
    }

    // calculate deletion diff
    final filesToDelete = filesAllowedToBeDeleted.values
        .expand((infos) => infos)
        .toSet()
        .difference(allFilesToKeep.toSet());
    return filesToDelete;
  }

  Future<_InfoMap> _collectDeletableFiles(
    Stream<RemoteFileInfo> files,
    int minKeep,
  ) =>
      files
          .groupBy((info) => info.volume)
          .asyncMap((group) async => MapEntry(group.key, await group.toList()))
          .mapValue(
            (infos) => infos
                .sortedBy((info) => info.backupDate)
                .reversed
                .skip(minKeep),
          )
          .toMap();

  _InfoMap _filterCount(_InfoMap infoMap, int minKeep, int maxKeep) {
    if (maxKeep <= minKeep) {
      throw ArgumentError.value(
        maxKeep,
        'maxKeep',
        'Must be greater than minKeep ($minKeep)',
      );
    }

    return infoMap.forValues((value) => value.take(maxKeep - minKeep));
  }

  _InfoMap _filterAge(_InfoMap infoMap, Duration maxAge) {
    final minDate = DateTime.now().subtract(maxAge);
    return infoMap.forValues(
      (value) => value.where((info) => info.backupDate.isAfter(minDate)),
    );
  }

  Iterable<RemoteFileInfo> _filterSize(
    Iterable<RemoteFileInfo> infos,
    int maxBytesTotal,
  ) {
    var sizeSum = 0;
    return infos
        .sortedByCompare(
          (info) => info.sizeInBytes,
          (a, b) => a - b,
        )
        .takeWhile((info) => (sizeSum += info.sizeInBytes) <= maxBytesTotal);
  }
}

extension _MapEntryStreamX<TKey, TValue> on Stream<MapEntry<TKey, TValue>> {
  Stream<MapEntry<TKey, TNewValue>> mapValue<TNewValue>(
    TNewValue Function(TValue) convert,
  ) =>
      map((e) => MapEntry(e.key, convert(e.value)));

  Future<Map<TKey, TValue>> toMap() async => {
        await for (final entry in this) entry.key: entry.value,
      };
}
