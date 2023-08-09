import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/process_adapter.dart';
import 'package:podman_backup/src/upload/upload_controller.dart';
import 'package:test/test.dart';

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
      testData<(Level, String?)>(
        'runs rsync with correct arguments',
        const [
          (Level.ALL, '--verbose'),
          (Level.FINEST, '--verbose'),
          (Level.FINER, '--progress'),
          (Level.FINE, null),
          (Level.CONFIG, null),
          (Level.INFO, null),
          (Level.WARNING, null),
          (Level.SEVERE, null),
          (Level.SHOUT, null),
          (Level.OFF, null),
        ],
        (fixture) async {
          const testRemoteHost = 'test.de:/test/path';

          Logger.root.level = fixture.$1;

          await sut.upload(
            remoteHost: testRemoteHost,
            cacheDir: testDir,
          );

          verify(
            () => mockProcessAdapter.run(
              'rsync',
              [
                if (fixture.$2 != null) fixture.$2!,
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
