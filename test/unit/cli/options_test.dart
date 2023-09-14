import 'dart:io';

import 'package:dart_test_tools/test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/environment_adapter.dart';
import 'package:podman_backup/src/adapters/posix_adapter.dart';
import 'package:podman_backup/src/cli/options.dart';
import 'package:test/test.dart';

class MockEnvironmentAdapter extends Mock implements EnvironmentAdapter {}

class MockPosixAdapter extends Mock implements PosixAdapter {}

void main() {
  group('$BackupMode', () {
    testData<(BackupMode, bool)>(
      'backup is mapped correctly',
      const [
        (BackupMode.full, true),
        (BackupMode.backupUpload, true),
        (BackupMode.uploadCleanup, false),
        (BackupMode.backupOnly, true),
        (BackupMode.uploadOnly, false),
        (BackupMode.cleanupOnly, false),
      ],
      (fixture) {
        expect(fixture.$1.backup, fixture.$2);
      },
    );

    testData<(BackupMode, bool)>(
      'upload is mapped correctly',
      const [
        (BackupMode.full, true),
        (BackupMode.backupUpload, true),
        (BackupMode.uploadCleanup, true),
        (BackupMode.backupOnly, false),
        (BackupMode.uploadOnly, true),
        (BackupMode.cleanupOnly, false),
      ],
      (fixture) {
        expect(fixture.$1.upload, fixture.$2);
      },
    );

    testData<(BackupMode, bool)>(
      'cleanup is mapped correctly',
      const [
        (BackupMode.full, true),
        (BackupMode.backupUpload, false),
        (BackupMode.uploadCleanup, true),
        (BackupMode.backupOnly, false),
        (BackupMode.uploadOnly, false),
        (BackupMode.cleanupOnly, true),
      ],
      (fixture) {
        expect(fixture.$1.cleanup, fixture.$2);
      },
    );
  });

  group('$Options', () {
    final mockEnvironmentAdapter = MockEnvironmentAdapter();
    final mockPosixAdapter = MockPosixAdapter();

    setUp(() {
      reset(mockEnvironmentAdapter);
      reset(mockPosixAdapter);

      when(() => mockPosixAdapter.isRoot).thenReturn(false);
    });

    group('sets correct backupCache defaults', () {
      test('sets correct path with HOME', () {
        when(() => mockEnvironmentAdapter['HOME'])
            .thenReturn('/home/test-user');

        final parser = Options.buildArgParser(
          mockEnvironmentAdapter,
          mockPosixAdapter,
        );

        final backupCacheOption = parser.options['backup-cache'];
        expect(backupCacheOption, isNotNull);
        expect(
          backupCacheOption!.defaultsTo,
          '/home/test-user/.cache/podman_backup',
        );
      });

      test('sets correct path without HOME', () {
        when(() => mockEnvironmentAdapter['HOME']).thenReturn(null);

        final parser = Options.buildArgParser(
          mockEnvironmentAdapter,
          mockPosixAdapter,
        );

        final backupCacheOption = parser.options['backup-cache'];
        expect(backupCacheOption, isNotNull);
        expect(
          backupCacheOption!.defaultsTo,
          '${Directory.systemTemp.path}/podman_backup',
        );
      });
    });

    testData<(bool, bool)>(
      'sets correct user defaults',
      const [
        (false, true),
        (true, false),
      ],
      (fixture) {
        when(() => mockPosixAdapter.isRoot).thenReturn(fixture.$1);

        final parser = Options.buildArgParser(
          mockEnvironmentAdapter,
          mockPosixAdapter,
        );

        final userOption = parser.options['user'];
        expect(userOption, isNotNull);
        expect(userOption!.defaultsTo, fixture.$2);
      },
    );

    testData<Level?>(
      'can parse all log levels',
      const [null, ...Level.LEVELS],
      (fixture) {
        final args = [
          if (fixture != null) '-L${fixture.name.toLowerCase()}',
        ];

        final parser = Options.buildArgParser(
          mockEnvironmentAdapter,
          mockPosixAdapter,
        );
        final options = Options.parseOptions(parser.parse(args));

        expect(options.logLevel, fixture ?? Level.INFO);
      },
    );

    group('getters', () {
      test('getRemoteHost returns remote host', () {
        const testRemoteHost = 'test-remote-host';
        final parser = Options.buildArgParser(
          mockEnvironmentAdapter,
          mockPosixAdapter,
        );
        final options = Options.parseOptions(
          parser.parse(const ['--remote', testRemoteHost]),
        );

        expect(options.getRemoteHost(), testRemoteHost);
      });

      testData<(List<String>, Duration?)>(
        'getMaxAge returns correct value',
        const [
          ([], null),
          (['--max-age', '10'], Duration(days: 10)),
        ],
        (fixture) {
          final parser = Options.buildArgParser(
            mockEnvironmentAdapter,
            mockPosixAdapter,
          );
          final options = Options.parseOptions(parser.parse(fixture.$1));

          expect(options.getMaxAge(), fixture.$2);
        },
      );

      testData<(List<String>, int?)>(
        'getMaxTotalSize returns correct value',
        const [
          ([], null),
          (['--max-total-size', '10'], 10 * 1024 * 1024),
        ],
        (fixture) {
          final parser = Options.buildArgParser(
            mockEnvironmentAdapter,
            mockPosixAdapter,
          );
          final options = Options.parseOptions(parser.parse(fixture.$1));

          expect(options.getMaxTotalSize(), fixture.$2);
        },
      );
    });
  });
}
