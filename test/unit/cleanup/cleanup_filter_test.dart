// ignore_for_file: discarded_futures

import 'dart:math';

import 'package:dart_test_tools/test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/date_time_adapter.dart';
import 'package:podman_backup/src/cleanup/cleanup_filter.dart';
import 'package:podman_backup/src/models/remote_file_info.dart';
import 'package:test/test.dart';

class MockDateTimeAdapter extends Mock implements DateTimeAdapter {}

void main() {
  group('$CleanupFilter', () {
    RemoteFileInfo rfi(String volume, DateTime backupDate, [int size = 0]) =>
        RemoteFileInfo(
          fileName: '$volume-$backupDate.tar.xz',
          sizeInBytes: size,
          volume: volume,
          backupDate: backupDate,
        );

    final mockDateTimeAdapter = MockDateTimeAdapter();

    late CleanupFilter sut;

    setUp(() {
      reset(mockDateTimeAdapter);

      when(
        () => mockDateTimeAdapter.utcNow,
      ).thenReturn(DateTime.utc(2023, 1, 15));

      sut = CleanupFilter(mockDateTimeAdapter);
    });

    test('throws if minKeep is less than 1', () {
      expect(
        () => sut.collectDeletableFiles(const Stream.empty(), minKeep: 0),
        throwsA(
          isArgumentError
              .having((m) => m.name, 'name', 'minKeep')
              .having((m) => m.invalidValue, 'invalidValue', 0),
        ),
      );
    });

    test(
      'logs warning and returns empty set if no cleanup options are specified',
      () {
        expect(
          Logger.root.onRecord,
          emits(
            isA<LogRecord>()
                .having((m) => m.level, 'level', Level.WARNING)
                .having((m) => m.loggerName, 'loggerName', '$CleanupFilter'),
          ),
        );

        expect(
          sut.collectDeletableFiles(const Stream.empty(), minKeep: 1),
          completion(isEmpty),
        );
      },
    );

    testData<
      (List<RemoteFileInfo>, int, int?, Duration?, int?, Set<RemoteFileInfo>)
    >(
      'correctly determines files to be deleted',
      dataToString:
          (fixture) =>
              'minKeep: ${fixture.$2}, maxKeep: ${fixture.$3}, '
              'maxAge: ${fixture.$4?.inDays}, maxBytesTotal: ${fixture.$5}',
      [
        ([], 1, null, null, null, {}),
        (
          [
            rfi('volume1', DateTime.utc(2023)),
            rfi('volume1', DateTime.utc(2023, 2)),
            rfi('volume1', DateTime.utc(2023, 3)),
            rfi('volume2', DateTime.utc(2023, 6)),
            rfi('volume2', DateTime.utc(2023, 4)),
            rfi('volume2', DateTime.utc(2023, 5)),
            rfi('volume3', DateTime.utc(2023, 9)),
            rfi('volume3', DateTime.utc(2023, 8)),
            rfi('volume3', DateTime.utc(2023, 7)),
          ],
          1,
          2,
          null,
          null,
          {
            rfi('volume1', DateTime.utc(2023)),
            rfi('volume2', DateTime.utc(2023, 4)),
            rfi('volume3', DateTime.utc(2023, 7)),
          },
        ),
        (
          [
            rfi('volume1', DateTime.utc(2023)),
            rfi('volume1', DateTime.utc(2023, 2)),
            rfi('volume1', DateTime.utc(2023, 3)),
            rfi('volume2', DateTime.utc(2023, 6)),
            rfi('volume2', DateTime.utc(2023, 4)),
            rfi('volume3', DateTime.utc(2023, 9)),
          ],
          2,
          2,
          null,
          null,
          {rfi('volume1', DateTime.utc(2023))},
        ),
        (
          [
            rfi('volume1', DateTime.utc(2023, 1, 8)),
            rfi('volume1', DateTime.utc(2023, 1, 9)),
            rfi(
              'volume1',
              DateTime.utc(
                2023,
                1,
                10,
              ).subtract(const Duration(microseconds: 1)),
            ),
            rfi('volume1', DateTime.utc(2023, 1, 10)),
            rfi('volume1', DateTime.utc(2023, 1, 11)),
            rfi('volume1', DateTime.utc(2023, 1, 12)),
            rfi('volume2', DateTime.utc(2023, 1, 5)),
            rfi('volume2', DateTime.utc(2023, 1, 6)),
            rfi('volume2', DateTime.utc(2023, 1, 7)),
          ],
          2,
          null,
          const Duration(days: 5),
          null,
          {
            rfi('volume1', DateTime.utc(2023, 1, 8)),
            rfi('volume1', DateTime.utc(2023, 1, 9)),
            rfi(
              'volume1',
              DateTime.utc(
                2023,
                1,
                10,
              ).subtract(const Duration(microseconds: 1)),
            ),
            rfi('volume2', DateTime.utc(2023, 1, 5)),
          },
        ),
        (
          [
            rfi('volume1', DateTime.utc(2023), 101),
            rfi('volume2', DateTime.utc(2023, 1, 2), 102),
            rfi('volume3', DateTime.utc(2023, 1, 3), 103),
            rfi('volume3', DateTime.utc(2023, 1, 4), 104),
            rfi('volume3', DateTime.utc(2023, 1, 5), 105),
            rfi('volume1', DateTime.utc(2023, 1, 6), 106),
            rfi('volume1', DateTime.utc(2023, 1, 7), 107),
            rfi('volume2', DateTime.utc(2023, 1, 8), 108),
            rfi('volume2', DateTime.utc(2023, 1, 9), 109),
            rfi('volume3', DateTime.utc(2023, 1, 10), 110),
            rfi('volume2', DateTime.utc(2023, 1, 11), 111),
            rfi('volume1', DateTime.utc(2023, 1, 12), 112),
            rfi('volume1', DateTime.utc(2023, 1, 13), 113),
            rfi('volume1', DateTime.utc(2023, 1, 14), 114),
            rfi('volume1', DateTime.utc(2023, 1, 15), 115),
          ],
          2,
          null,
          null,
          1000,
          {
            rfi('volume1', DateTime.utc(2023), 101),
            rfi('volume2', DateTime.utc(2023, 1, 2), 102),
            rfi('volume3', DateTime.utc(2023, 1, 3), 103),
            rfi('volume3', DateTime.utc(2023, 1, 4), 104),
            rfi('volume1', DateTime.utc(2023, 1, 6), 106),
            rfi('volume1', DateTime.utc(2023, 1, 7), 107),
          },
        ),
        (
          [
            rfi('volume1', DateTime.utc(2023, 1, 11)),
            rfi('volume1', DateTime.utc(2023, 1, 12)),
            rfi('volume1', DateTime.utc(2023, 1, 13)),
            rfi('volume1', DateTime.utc(2023, 1, 14)),
            rfi('volume1', DateTime.utc(2023, 1, 15)),
            rfi('volume2', DateTime.utc(2023, 1, 4)),
            rfi('volume2', DateTime.utc(2023, 1, 9)),
            rfi('volume2', DateTime.utc(2023, 1, 14)),
            rfi('volume3', DateTime.utc(2023, 1, 4)),
            rfi('volume3', DateTime.utc(2023, 1, 5)),
          ],
          1,
          3,
          const Duration(days: 5),
          null,
          {
            rfi('volume1', DateTime.utc(2023, 1, 11)),
            rfi('volume1', DateTime.utc(2023, 1, 12)),
            rfi('volume2', DateTime.utc(2023, 1, 4)),
            rfi('volume2', DateTime.utc(2023, 1, 9)),
            rfi('volume3', DateTime.utc(2023, 1, 4)),
          },
        ),
        (
          [
            rfi('volume1', DateTime.utc(2023, 1, 11), 500),
            rfi('volume1', DateTime.utc(2023, 1, 12), 400),
            rfi('volume1', DateTime.utc(2023, 1, 13), 300),
            rfi('volume1', DateTime.utc(2023, 1, 14), 200),
            rfi('volume1', DateTime.utc(2023, 1, 15), 100),
            rfi('volume2', DateTime.utc(2023, 1, 5), 400),
            rfi('volume2', DateTime.utc(2023, 1, 6), 400),
          ],
          1,
          3,
          null,
          1000,
          {
            rfi('volume1', DateTime.utc(2023, 1, 11), 500),
            rfi('volume1', DateTime.utc(2023, 1, 12), 400),
            rfi('volume2', DateTime.utc(2023, 1, 5), 400),
          },
        ),
        (
          [
            rfi('volume1', DateTime.utc(2023, 1, 8), 500),
            rfi('volume1', DateTime.utc(2023, 1, 9), 400),
            rfi('volume1', DateTime.utc(2023, 1, 10), 300),
            rfi('volume1', DateTime.utc(2023, 1, 11), 200),
            rfi('volume1', DateTime.utc(2023, 1, 12), 100),
            rfi('volume2', DateTime.utc(2023, 1, 10), 300),
            rfi('volume2', DateTime.utc(2023, 1, 11), 300),
            rfi('volume2', DateTime.utc(2023, 1, 12), 300),
            rfi('volume3', DateTime.utc(2023, 1, 5), 100),
          ],
          1,
          null,
          const Duration(days: 5),
          1000,
          {
            rfi('volume1', DateTime.utc(2023, 1, 8), 500),
            rfi('volume1', DateTime.utc(2023, 1, 9), 400),
            rfi('volume1', DateTime.utc(2023, 1, 10), 300),
            rfi('volume2', DateTime.utc(2023, 1, 10), 300),
          },
        ),
        (
          [
            rfi('volume1', DateTime.utc(2023, 1, 10), 200),
            rfi('volume1', DateTime.utc(2023, 1, 11), 200),
            rfi('volume1', DateTime.utc(2023, 1, 12), 200),
            rfi('volume1', DateTime.utc(2023, 1, 13), 200),
            rfi('volume1', DateTime.utc(2023, 1, 14), 200),
            rfi('volume2', DateTime.utc(2023, 1, 5), 300),
            rfi('volume2', DateTime.utc(2023, 1, 10), 300),
            rfi('volume2', DateTime.utc(2023, 1, 15), 300),
            rfi('volume3', DateTime.utc(2023, 1, 10), 300),
            rfi('volume3', DateTime.utc(2023, 1, 10), 300),
            rfi('volume3', DateTime.utc(2023, 1, 10), 300),
          ],
          1,
          3,
          const Duration(days: 5),
          1000,
          {
            rfi('volume1', DateTime.utc(2023, 1, 10), 200),
            rfi('volume1', DateTime.utc(2023, 1, 11), 200),
            rfi('volume1', DateTime.utc(2023, 1, 12), 200),
            rfi('volume2', DateTime.utc(2023, 1, 5), 300),
            rfi('volume2', DateTime.utc(2023, 1, 10), 300),
            rfi('volume3', DateTime.utc(2023, 1, 10), 300),
          },
        ),
      ],
      (fixture) async {
        final result = await sut.collectDeletableFiles(
          Stream.fromIterable(fixture.$1..shuffle(Random.secure())),
          minKeep: fixture.$2,
          maxKeep: fixture.$3,
          maxAge: fixture.$4,
          maxBytesTotal: fixture.$5,
        );

        expect(result, fixture.$6);
      },
    );
  });
}
