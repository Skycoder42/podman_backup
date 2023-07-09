import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/process_adapter.dart';
import 'package:podman_backup/src/upload/upload_controller.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

class MockProcessAdapter extends Mock implements ProcessAdapter {}

void main() {
  group('$UploadController', () {
    final mockProcessAdapter = MockProcessAdapter();

    late Directory testDir;
    late UploadController sut;

    setUp(() async {
      reset(mockProcessAdapter);

      when(() => mockProcessAdapter.run(any(), any())).thenReturnAsync(0);

      testDir = await Directory.systemTemp.createTemp();
      sut = UploadController(mockProcessAdapter);
    });

    tearDown(() async {
      await testDir.delete(recursive: true);
    });

    group('upload', () {
      testData<Tuple2<Level, String?>>(
        'runs rsync with correct arguments',
        const [
          Tuple2(Level.ALL, '--verbose'),
          Tuple2(Level.FINEST, '--verbose'),
          Tuple2(Level.FINER, '--progress'),
          Tuple2(Level.FINE, null),
          Tuple2(Level.CONFIG, null),
          Tuple2(Level.INFO, null),
          Tuple2(Level.WARNING, null),
          Tuple2(Level.SEVERE, null),
          Tuple2(Level.SHOUT, null),
          Tuple2(Level.OFF, null),
        ],
        (fixture) async {
          const testRemoteHost = 'test.de:/test/path';

          Logger.root.level = fixture.item1;

          await sut.upload(
            remoteHost: testRemoteHost,
            cacheDir: testDir,
          );

          verify(
            () => mockProcessAdapter.run(
              'rsync',
              [
                if (fixture.item2 != null) fixture.item2!,
                '--recursive',
                '--copy-links',
                '--times',
                '--remove-source-files',
                '--human-readable',
                '${testDir.path}/',
                '$testRemoteHost/',
              ],
            ),
          );
        },
      );
    });
  });
}
