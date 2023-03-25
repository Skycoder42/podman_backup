import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/compress_adapter.dart';
import 'package:podman_backup/src/adapters/process_adapter.dart';
import 'package:test/test.dart';

class MockProcessAdapter extends Mock implements ProcessAdapter {}

void main() {
  group('$CompressAdapter', () {
    final mockProcessAdapter = MockProcessAdapter();

    late CompressAdapter sut;

    setUp(() {
      reset(mockProcessAdapter);

      sut = CompressAdapter(mockProcessAdapter);
    });

    test('compress invokes xz process', () async {
      final inStream = Stream.value(
        List.generate(100, (index) => index),
      );
      final outData = List.filled(20, 20);

      when(
        () => mockProcessAdapter.streamRaw(
          any(),
          any(),
          stdin: any(named: 'stdin'),
        ),
      ).thenStream(Stream.value(outData));

      final stream = sut.compress(inStream);
      await expectLater(
        stream,
        emitsInOrder(<dynamic>[
          outData,
          emitsDone,
        ]),
      );

      verify(
        () => mockProcessAdapter.streamRaw(
          'xz',
          [
            '--compress',
            '-9',
            '--threads',
            (Platform.numberOfProcessors ~/ 2).toString(),
          ],
          stdin: inStream,
        ),
      );
    });
  });
}
