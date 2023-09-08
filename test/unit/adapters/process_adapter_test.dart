// ignore_for_file: discarded_futures

import 'dart:convert';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/process_adapter.dart';
import 'package:test/test.dart';

class MockStdout extends Mock implements Stdout {}

void main() {
  group('$ProcessAdapter', () {
    final mockStderr = MockStdout();

    late ProcessAdapter sut;

    setUp(() {
      reset(mockStderr);

      sut = ProcessAdapter(mockStderr);
    });

    tearDown(() {
      verifyNoMoreInteractions(mockStderr);
    });

    group('run', () {
      test('runs executable', () {
        final result = sut.run('bash', const [
          '-c',
          'echo out; >&2 echo err',
        ]);

        expect(result, completion(0));
      });

      test('throws for unexpected exit code', () {
        const arguments = ['-c', 'exit 1'];
        expect(
          sut.run('bash', arguments),
          throwsA(
            isA<ProcessFailed>()
                .having((m) => m.executable, 'executable', 'bash')
                .having((m) => m.arguments, 'arguments', arguments)
                .having((m) => m.exitCode, 'exitCode', 1),
          ),
        );
      });

      test('throws for custom unexpected exit code', () {
        const arguments = ['-c', 'exit 0'];
        expect(
          sut.run('bash', arguments, expectedExitCode: 10),
          throwsA(
            isA<ProcessFailed>()
                .having((m) => m.executable, 'executable', 'bash')
                .having((m) => m.arguments, 'arguments', arguments)
                .having((m) => m.exitCode, 'exitCode', 0),
          ),
        );
      });

      test('does not throw if disabled', () {
        final result = sut.run(
          'bash',
          ['-c', 'exit 1'],
          expectedExitCode: null,
        );

        expect(result, completion(1));
      });
    });

    group('streamRaw', () {
      test('streams lines of process output', () {
        final stream = sut.streamRaw('bash', const [
          '-c',
          'echo line1; echo line2; echo; echo -n line3; echo line4',
        ]);

        final expected = StringBuffer()
          ..writeln('line1')
          ..writeln('line2')
          ..writeln()
          ..writeln('line3line4');
        final expectedBytes = systemEncoding.encode(expected.toString());

        expect(
          stream.expand((bytes) => bytes),
          emitsInOrder(<dynamic>[
            ...expectedBytes,
            emitsDone,
          ]),
        );
      });

      test('forwards stderr to dart stderr', () async {
        final stream = sut.streamRaw('bash', const [
          '-c',
          'echo out1; >&2 echo err1; echo out2; >&2 echo err2',
        ]);

        await stream.drain<void>();

        verifyInOrder([
          () => mockStderr.writeln('err1'),
          () => mockStderr.writeln('err2'),
        ]);
      });

      test('forwards stdin to child process if given', () {
        final expected = StringBuffer()
          ..writeln('line1')
          ..writeln('line2')
          ..writeln()
          ..writeln('line3line4');
        final expectedBytes = systemEncoding.encode(expected.toString());

        final stream = sut.streamRaw(
          'cat',
          const [],
          stdin: Stream.value(expectedBytes),
        );

        expect(
          stream.expand((bytes) => bytes),
          emitsInOrder(<dynamic>[
            ...expectedBytes,
            emitsDone,
          ]),
        );
      });

      test('emits error on unexpected exit code', () {
        const arguments = ['-c', 'echo line1; exit 1'];
        final stream = sut.streamRaw('bash', arguments);

        final expectedBytes = systemEncoding.encode('line1\n');

        expect(
          stream.expand((bytes) => bytes),
          emitsInOrder(<dynamic>[
            ...expectedBytes,
            emitsError(
              isA<ProcessFailed>()
                  .having((m) => m.executable, 'executable', 'bash')
                  .having((m) => m.arguments, 'arguments', arguments)
                  .having((m) => m.exitCode, 'exitCode', 1),
            ),
            emitsDone,
          ]),
        );
      });

      test('emits error on custom unexpected exit code', () {
        const arguments = ['-c', 'echo line1'];
        final stream = sut.streamRaw(
          'bash',
          arguments,
          expectedExitCode: 42,
        );

        final expectedBytes = systemEncoding.encode('line1\n');

        expect(
          stream.expand((bytes) => bytes),
          emitsInOrder(<dynamic>[
            ...expectedBytes,
            emitsError(
              isA<ProcessFailed>()
                  .having((m) => m.executable, 'executable', 'bash')
                  .having((m) => m.arguments, 'arguments', arguments)
                  .having((m) => m.exitCode, 'exitCode', 0),
            ),
            emitsDone,
          ]),
        );
      });

      test('does not emit error if exit code validation is disabled', () {
        final stream = sut.streamRaw(
          'bash',
          ['-c', 'echo line1; exit 12'],
          expectedExitCode: null,
        );

        final expectedBytes = systemEncoding.encode('line1\n');

        expect(
          stream.expand((bytes) => bytes),
          emitsInOrder(<dynamic>[
            ...expectedBytes,
            emitsDone,
          ]),
        );
      });
    });

    group('streamLines', () {
      test('streams lines of process output', () {
        final stream = sut.streamLines('bash', const [
          '-c',
          'echo line1; echo line2; echo; echo -n line3; echo line4',
        ]);

        expect(
          stream,
          emitsInOrder(<dynamic>[
            'line1',
            'line2',
            '',
            'line3line4',
            emitsDone,
          ]),
        );
      });

      test('forwards stderr to dart stderr', () async {
        final stream = sut.streamLines('bash', const [
          '-c',
          'echo out1; >&2 echo err1; echo out2; >&2 echo err2',
        ]);

        await stream.drain<void>();

        verifyInOrder([
          () => mockStderr.writeln('err1'),
          () => mockStderr.writeln('err2'),
        ]);
      });

      test('forwards stdin to child process if given', () {
        final expectedLines = [
          'line1',
          'line2',
          '',
          'line3line4',
        ];

        final stream = sut.streamLines(
          'cat',
          const [],
          stdinLines: Stream.fromIterable(expectedLines),
        );

        expect(
          stream,
          emitsInOrder(<dynamic>[
            ...expectedLines,
            emitsDone,
          ]),
        );
      });

      test('emits error on unexpected exit code', () {
        const arguments = ['-c', 'echo line1; exit 1'];
        final stream = sut.streamLines('bash', arguments);

        expect(
          stream,
          emitsInOrder(<dynamic>[
            'line1',
            emitsError(
              isA<ProcessFailed>()
                  .having((m) => m.executable, 'executable', 'bash')
                  .having((m) => m.arguments, 'arguments', arguments)
                  .having((m) => m.exitCode, 'exitCode', 1),
            ),
            emitsDone,
          ]),
        );
      });

      test('emits error on custom unexpected exit code', () {
        const arguments = ['-c', 'echo line1'];
        final stream = sut.streamLines(
          'bash',
          arguments,
          expectedExitCode: 42,
        );

        expect(
          stream,
          emitsInOrder(<dynamic>[
            'line1',
            emitsError(
              isA<ProcessFailed>()
                  .having((m) => m.executable, 'executable', 'bash')
                  .having((m) => m.arguments, 'arguments', arguments)
                  .having((m) => m.exitCode, 'exitCode', 0),
            ),
            emitsDone,
          ]),
        );
      });

      test('does not emit error if exit code validation is disabled', () {
        final stream = sut.streamLines(
          'bash',
          ['-c', 'echo line1; exit 12'],
          expectedExitCode: null,
        );

        expect(
          stream,
          emitsInOrder(<dynamic>[
            'line1',
            emitsDone,
          ]),
        );
      });
    });

    group('streamJson', () {
      test('streams json of process output', () {
        final jsonData = {
          'id': 42,
          'name': 'json',
          'steps': [1, 2, 3],
          'enabled': true,
          'properties': {
            'a': 1.23,
            'b': [
              1,
              true,
              'yes',
              [1.2, 3],
            ],
          },
        };

        final result = sut.streamJson('bash', [
          '-c',
          "echo '${json.encode(jsonData)}'",
        ]);

        expect(
          result,
          completion(jsonData),
        );
      });

      test('forwards stderr to dart stderr', () async {
        await sut.streamJson('bash', [
          '-c',
          ">&2 echo err1; echo 'null'; >&2 echo err2",
        ]);

        verifyInOrder([
          () => mockStderr.writeln('err1'),
          () => mockStderr.writeln('err2'),
        ]);
      });

      test('emits error on unexpected exit code', () {
        const arguments = ['-c', "echo '42'; exit 1"];
        expect(
          sut.streamJson('bash', arguments),
          throwsA(
            isA<ProcessFailed>()
                .having((m) => m.executable, 'executable', 'bash')
                .having((m) => m.arguments, 'arguments', arguments)
                .having((m) => m.exitCode, 'exitCode', 1),
          ),
        );
      });

      test('emits error on custom unexpected exit code', () {
        const arguments = ['-c', "echo '[1, 2, 3]'; exit 0"];
        expect(
          sut.streamJson(
            'bash',
            arguments,
            expectedExitCode: 1,
          ),
          throwsA(
            isA<ProcessFailed>()
                .having((m) => m.executable, 'executable', 'bash')
                .having((m) => m.arguments, 'arguments', arguments)
                .having((m) => m.exitCode, 'exitCode', 0),
          ),
        );
      });

      test('does not emit error if exit code validation is disabled', () {
        const arguments = ['-c', "echo '\"hello\"'; exit 111"];
        expect(
          sut.streamJson(
            'bash',
            arguments,
            expectedExitCode: null,
          ),
          completes,
        );
      });
    });
  });
}
