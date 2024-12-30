import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/process_adapter.dart';
import 'package:podman_backup/src/adapters/sftp_adapter.dart';
import 'package:test/test.dart';

class MockProcessAdapter extends Mock implements ProcessAdapter {}

void main() {
  group('$SftpAdapter', () {
    const testRemoteHost = 'test-remote-host';
    const testPath = 'test/path';

    final mockProcessAdapter = MockProcessAdapter();

    late SftpAdapter sut;

    setUp(() {
      reset(mockProcessAdapter);

      when(
        () => mockProcessAdapter.streamLines(
          any(),
          any(),
          stdinLines: any(named: 'stdinLines'),
        ),
      ).thenStream(const Stream.empty());

      sut = SftpAdapter(mockProcessAdapter);
    });

    test('returns stream of process adapter', () {
      final testStream = Stream.fromIterable(['a', 'b', 'c']);
      when(
        () => mockProcessAdapter.streamLines(
          any(),
          any(),
          stdinLines: any(named: 'stdinLines'),
        ),
      ).thenStream(testStream);

      final batch = sut.batch(testRemoteHost)..ls();

      final result = batch.execute();

      expect(result, testStream);
    });

    testData<(bool, bool, bool, bool, String)>(
      'executes correct ls command',
      [
        (false, false, false, false, 'ls -1'),
        (false, false, false, true, '-ls -1'),
        (false, false, true, false, '@ls -1'),
        (false, false, true, true, '-@ls -1'),
        (false, true, false, false, 'ls -l'),
        (false, true, false, true, '-ls -l'),
        (false, true, true, false, '@ls -l'),
        (false, true, true, true, '-@ls -l'),
        (true, false, false, false, 'ls -1 -a'),
        (true, false, false, true, '-ls -1 -a'),
        (true, false, true, false, '@ls -1 -a'),
        (true, false, true, true, '-@ls -1 -a'),
        (true, true, false, false, 'ls -l -a'),
        (true, true, false, true, '-ls -l -a'),
        (true, true, true, false, '@ls -l -a'),
        (true, true, true, true, '-@ls -l -a'),
      ],
      (fixture) async {
        final batch = sut.batch(testRemoteHost)
          ..ls(
            allFiles: fixture.$1,
            withDetails: fixture.$2,
            noEcho: fixture.$3,
            ignoreResult: fixture.$4,
          );

        await batch.execute().drain<void>();

        verify(
          () => mockProcessAdapter.streamLines(
            'sftp',
            const ['-b', '-', testRemoteHost],
            stdinLines: any(
              named: 'stdinLines',
              that: emitsInOrder(<dynamic>[
                fixture.$5,
                emitsDone,
              ]),
            ),
          ),
        );
      },
    );

    testData<(bool, bool, String)>(
      'executes correct rm command',
      [
        (false, false, "rm '$testPath'"),
        (false, true, "-rm '$testPath'"),
        (true, false, "@rm '$testPath'"),
        (true, true, "-@rm '$testPath'"),
      ],
      (fixture) async {
        final batch = sut.batch(testRemoteHost)
          ..rm(
            testPath,
            noEcho: fixture.$1,
            ignoreResult: fixture.$2,
          );

        await batch.execute().drain<void>();

        verify(
          () => mockProcessAdapter.streamLines(
            'sftp',
            const ['-b', '-', testRemoteHost],
            stdinLines: any(
              named: 'stdinLines',
              that: emitsInOrder(<dynamic>[
                fixture.$3,
                emitsDone,
              ]),
            ),
          ),
        );
      },
    );

    test('throws for empty batch', () async {
      expect(
        () => sut.batch(testRemoteHost).execute().drain<void>(),
        throwsStateError,
      );
    });
  });
}
