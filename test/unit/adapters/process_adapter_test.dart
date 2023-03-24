import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/process_adapter.dart';
import 'package:test/test.dart';

class MockStdout extends Mock implements Stdout {}

void main() {
  group('$ProcessAdapter', () {
    final mockStdout = MockStdout();

    late ProcessAdapter sut;

    setUp(() {
      reset(mockStdout);

      sut = ProcessAdapter(mockStdout);
    });

    tearDown(() {
      verifyNoMoreInteractions(mockStdout);
    });

    group('run', () {
      test('runs executable', () async {
        final result = await sut.run('bash', const [
          '-c',
          'echo out; >&2 echo err',
        ]);

        expect(result, 0);
      });
    });
  });
}
