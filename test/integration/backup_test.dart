// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

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

    test('can backup a single volume with simple replacement hook', () async {
      // arrange
      final extraBackupDir = await Directory('/tmp/backup').create();
      addTearDown(() => extraBackupDir.delete(recursive: true));

      const volume = 'test-volume-s1-1';
      await createVolume(volume, hook: 'test-backup-hook.service');
      await startService('test-service-1.service');
      logUnitOnFailure('test-backup-hook.service');

      // act
      await runSut();

      // assert
      expect(cacheDir.list().length, completion(0));
      expect(extraBackupDir.list().length, completion(2)); // data and timestamp
      await verifyVolumeContent(extraBackupDir, volume);

      _expectStateLogs('test-service-1.service', const [
        _State.started,
        _State.stopped,
        _State.started,
      ]);
    });

    test('can backup a single volume with template pre-hook', () async {
      // arrange
      const volume = 'test-volume-s1-1';
      await createVolume(volume, hook: '!test-pre-hook@.service');
      await startService('test-service-1.service');
      logUnitOnFailure('test-pre-hook@$volume.service');

      // act
      await runSut();

      // assert
      expect(cacheDir.list().length, completion(1));
      await verifyVolume(cacheDir, volume, withInfo: true);

      _expectStateLogs('test-service-1.service', const [
        _State.started,
        _State.stopped,
        _State.started,
      ]);
    });

    // TODO add in full test

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
        volume24,
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

    test('can backup a pod container', () async {
      // arrange
      const volume1 = 'test-volume-1';
      const volume2 = 'test-volume-2';

      await createVolume(volume1);
      await createVolume(volume2);
      await startService('test-pod.service');

      // act
      await runSut();

      // assert
      expect(cacheDir.list().length, completion(2));
      await verifyVolume(cacheDir, volume1);
      await verifyVolume(cacheDir, volume2);

      // wait a few seconds for containers to be started
      await Future<void>.delayed(const Duration(seconds: 5));
      _expectStateLogs('test-pod.service', const [
        _State.started,
        _State.stopped,
        _State.started,
      ]);
      _expectStateLogs('test-pod-container-1.service', const [
        _State.started,
        _State.stopped,
        _State.started,
      ]);
      _expectStateLogs('test-pod-container-2.service', const [
        _State.started,
        _State.stopped,
        _State.started,
      ]);
    });
  }

  void _expectStateLogs(String service, List<_State> states) {
    final stateCounts = <_State, int>{_State.started: 0, _State.stopped: 0};
    for (final state in states) {
      stateCounts[state] = stateCounts[state]! + 1;
    }

    expect(
      // ignore: discarded_futures
      journalctl(service).toList(),
      completion(
        allOf(
          _containsNStates(
            stateCounts[_State.started]!,
            service,
            _State.started,
          ),
          _containsNStates(
            stateCounts[_State.stopped]!,
            service,
            _State.stopped,
          ),
          _containsStatesInOrder(service, states),
        ),
      ),
    );
  }

  Matcher _containsStatesInOrder(String service, List<_State> states) =>
      containsAllInOrder(<Matcher>[
        for (final state in states) endsWith(_logStatement(service, state)),
      ]);

  Matcher _containsNStates(int n, String service, _State state) =>
      _containsNWhere<String>(
        n,
        (e) => e.endsWith(_logStatement(service, state)),
        'has exactly $n elements that end with: '
        '${_logStatement(service, state)}',
      );

  Matcher _containsNWhere<T>(
    int n,
    bool Function(T) filter, [
    String? description,
  ]) => predicate<List<T>>(
    (l) => l.where(filter).length == n,
    description ?? 'has exactly $n elements that match the filter predicate',
  );

  String _logStatement(String service, _State state) =>
      '${state.value} $service - Podman $service.';
}

enum _State {
  started('Started'),
  stopped('Stopped');

  final String value;

  const _State(this.value);
}
