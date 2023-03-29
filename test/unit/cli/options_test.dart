import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/environment_adapter.dart';
import 'package:podman_backup/src/cli/options.dart';
import 'package:test/test.dart';
import 'package:tuple/tuple.dart';

class MockEnvironmentAdapter extends Mock implements EnvironmentAdapter {}

void main() {
  group('$BackupMode', () {
    testData<Tuple2<BackupMode, bool>>(
      'backup is mapped correctly',
      const [
        Tuple2(BackupMode.full, true),
        Tuple2(BackupMode.backupOnly, true),
        Tuple2(BackupMode.uploadOnly, false),
      ],
      (fixture) {
        expect(fixture.item1.backup, fixture.item2);
      },
    );
    testData<Tuple2<BackupMode, bool>>(
      'upload is mapped correctly',
      const [
        Tuple2(BackupMode.full, true),
        Tuple2(BackupMode.backupOnly, false),
        Tuple2(BackupMode.uploadOnly, true),
      ],
      (fixture) {
        expect(fixture.item1.upload, fixture.item2);
      },
    );
  });

  group('$Options', () {
    final mockEnvironmentAdapter = MockEnvironmentAdapter();

    setUp(() {
      reset(mockEnvironmentAdapter);
    });

    group('sets correct backupCache defaults', () {
      test('sets correct path with HOME', () {
        when(() => mockEnvironmentAdapter['HOME'])
            .thenReturn('/home/test-user');

        final parser = Options.buildArgParser(mockEnvironmentAdapter);

        final backupCacheOption = parser.options['backup-cache'];
        expect(backupCacheOption, isNotNull);
        expect(
          backupCacheOption!.defaultsTo,
          '/home/test-user/.cache/podman_backup',
        );
      });

      test('sets correct path without HOME', () {
        when(() => mockEnvironmentAdapter['HOME']).thenReturn(null);

        final parser = Options.buildArgParser(mockEnvironmentAdapter);

        final backupCacheOption = parser.options['backup-cache'];
        expect(backupCacheOption, isNotNull);
        expect(
          backupCacheOption!.defaultsTo,
          '${Directory.systemTemp.path}/podman_backup',
        );
      });
    });

    testData<Level?>(
      'can parse all log levels',
      const [null, ...Level.LEVELS],
      (fixture) {
        final args = [
          if (fixture != null) '-L${fixture.name.toLowerCase()}',
        ];

        final parser = Options.buildArgParser(mockEnvironmentAdapter);
        final options = Options.parseOptions(parser.parse(args));

        expect(options.logLevel, fixture ?? Level.INFO);
      },
    );
  });
}
