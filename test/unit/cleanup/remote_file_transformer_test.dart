// ignore_for_file: unnecessary_lambdas

import 'dart:async';

import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/cleanup/remote_file_transformer.dart';
import 'package:podman_backup/src/models/remote_file_info.dart';
import 'package:test/test.dart';

class MockEventSink<T> extends Mock implements EventSink<T> {}

void main() {
  const testLine = '-rw-r--r-- 1 vscode vscode  1203 Sep  5 2023 '
      'my-backup-file-2023_04_12_10_15_44.tar.xz';
  final testRemoteFileInfo = RemoteFileInfo(
    fileName: 'my-backup-file-2023_04_12_10_15_44.tar.xz',
    sizeInBytes: 1203,
    volume: 'my-backup-file',
    backupDate: DateTime.utc(2023, 4, 12, 10, 15, 44),
  );

  group('$RemoteFileTransformerSink', () {
    final mockEventSink = MockEventSink<RemoteFileInfo>();

    late RemoteFileTransformerSink sut;

    setUp(() {
      reset(mockEventSink);

      sut = RemoteFileTransformerSink(mockEventSink);
    });

    tearDown(() {
      verifyNoMoreInteractions(mockEventSink);
    });

    group('add', () {
      test('adds mapped line to sink', () {
        sut.add(testLine);

        verify(
          () => mockEventSink.add(testRemoteFileInfo),
        );
      });

      testData<(String, Matcher)>(
        'adds error if line is invalid',
        [
          (
            'not enough fields',
            isStateError.having(
              (m) => m.message,
              'message',
              contains('Pattern matching error'),
            )
          ),
          (
            '1 2 3 4 5 6 7 8 9 extra_element',
            isFormatException
                .having(
                  (m) => m.message,
                  'message',
                  'Not a valid sftp "ls -l" line',
                )
                .having(
                  (m) => m.source,
                  'source',
                  '1 2 3 4 5 6 7 8 9 extra_element',
                ),
          ),
          (
            '1 2 3 4 5 6 7 8 invalid_backup_file_name',
            isFormatException
                .having(
                  (m) => m.message,
                  'message',
                  'Not a valid backup file name',
                )
                .having(
                  (m) => m.source,
                  'source',
                  'invalid_backup_file_name',
                ),
          ),
          (
            '1 2 3 4 not_a_number 6 7 8 volume-0001_01_01_00_00_00.tar.xz',
            isFormatException
                .having(
                  (m) => m.message,
                  'message',
                  contains('Invalid radix-10 number'),
                )
                .having((m) => m.source, 'source', 'not_a_number'),
          ),
        ],
        (fixture) {
          sut.add(fixture.$1);

          verify(
            () => mockEventSink.addError(
              any(that: fixture.$2),
              any(that: isNotNull),
            ),
          );
        },
      );
    });

    test('addError forwards error to sink', () {
      final error = Exception('test');
      final stackTrace = StackTrace.current;

      sut.addError(error, stackTrace);

      verify(() => mockEventSink.addError(error, stackTrace));
    });

    test('close calls close to sink', () {
      sut.close();

      verify(() => mockEventSink.close());
    });
  });

  group('$RemoteFileTransformer', () {
    test('bind creates RemoteFileTransformerSink transformed', () {
      expect(
        Stream.value(testLine).transform(const RemoteFileTransformer()),
        emits(testRemoteFileInfo),
      );
    });
  });
}
