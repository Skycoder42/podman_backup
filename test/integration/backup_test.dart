// ignore_for_file: avoid_print

import 'dart:async';

import 'package:podman_backup/src/cli/options.dart';
import 'package:test/test.dart';

import 'integration_test_case.dart';

void main() => BackupTestCase().run();

class BackupTestCase extends IntegrationTestCase {
  @override
  String get name => 'backup';

  Future<void> runSut() => runPodmanBackup(
        backupMode: BackupMode.backupOnly,
        backupDir: backupDir,
        cacheDir: cacheDir,
      );

  @override
  void build() {
    test('can backup a single, unattached volume', () async {
      // arrange
      const volume1 = 'test-volume-1';
      const volume2 = 'test-volume-2';

      await createVolume(volume1);
      await createVolume(volume2, backedUp: false);

      // act
      await runSut();

      // assert
      expect(cacheDir.list().length, completion(1));
      await verifyVolume(cacheDir, volume1);
    });

    test('can backup a single, attached volume', () async {
      // arrange
      const volume = 'test-volume-s1-1';

      await createVolume(volume);
      await startService('test-service-1.service');

      // act
      await runSut();

      // assert
      expect(cacheDir.list().length, completion(1));
      await verifyVolume(cacheDir, volume);

      _expectStateLogs('test-service-1.service', const [
        _State.started,
        _State.stopped,
        _State.started,
      ]);
    });

    test('can backup a multiple, cross-attached volumes', () async {
      // arrange
      const volume11 = 'test-volume-s1-1';
      const volume21 = 'test-volume-s2-1';
      const volume22 = 'test-volume-s2-2';
      const volume23 = 'test-volume-s2-3';
      const volume24 = 'test-volume-s2-4';
      const volume25 = 'test-volume-s2-5';
      const backedUpVolumes = [
        volume11,
        volume21,
        volume22,
        volume23,
        volume24
      ];

      for (final volume in backedUpVolumes) {
        await createVolume(volume);
      }
      await createVolume(volume25, backedUp: false);
      await startService('test-service-1.service');
      await startService('test-service-2.service');
      await startService('test-service-3.service');
      await startService('test-service-4.service');
      await startService('test-service-5.service');

      // act
      await runSut();

      // assert
      expect(cacheDir.list().length, completion(backedUpVolumes.length));
      for (final volume in backedUpVolumes) {
        await verifyVolume(cacheDir, volume);
      }

      _expectStateLogs('test-service-1.service', const [
        _State.started,
        _State.stopped,
        _State.started,
      ]);
      _expectStateLogs('test-service-2.service', const [
        _State.started,
        _State.stopped,
        _State.started,
      ]);
      _expectStateLogs('test-service-3.service', const [
        _State.started,
        _State.stopped,
        _State.started,
      ]);
      _expectStateLogs('test-service-4.service', const [
        _State.started,
        _State.stopped,
        _State.started,
      ]);
      _expectStateLogs('test-service-5.service', [_State.started]);
    });
  }

  void _expectStateLogs(String service, Iterable<_State> states) => expect(
        // ignore: discarded_futures
        journalctl(service).toList(),
        completion(
          containsAllInOrder(<Matcher>[
            ...states.map(
              (s) => endsWith('${s.value} Podman $service.'),
            ),
            ..._State.values.map(
              (s) => isNot(
                endsWith('${s.value} Podman $service.'),
              ),
            ),
          ]),
        ),
      );
}

enum _State {
  started('Started'),
  stopped('Stopped');

  final String value;

  const _State(this.value);
}
