// ignore_for_file: discarded_futures

import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/process_adapter.dart';
import 'package:podman_backup/src/adapters/systemctl_adapter.dart';
import 'package:test/test.dart';

class MockProcessAdapter extends Mock implements ProcessAdapter {}

void main() {
  group('$SystemctlAdapter', () {
    final mockProcessAdapter = MockProcessAdapter();

    late SystemctlAdapter sut;

    setUp(() {
      reset(mockProcessAdapter);

      when(() => mockProcessAdapter.run(any(), any())).thenReturnAsync(0);

      sut = SystemctlAdapter(mockProcessAdapter);
    });

    testData<bool>(
      'start invokes systemd start',
      const [true, false],
      (fixture) async {
        const testUnit = 'test.service';
        sut.runAsUser = fixture;

        await sut.start(testUnit);

        verify(
          () => mockProcessAdapter.run(
            'systemctl',
            [if (fixture) '--user', 'start', testUnit],
          ),
        );
      },
    );

    testData<bool>(
      'stop invokes systemd stop',
      const [true, false],
      (fixture) async {
        const testUnit = 'test.service';
        sut.runAsUser = fixture;

        await sut.stop(testUnit);

        verify(
          () => mockProcessAdapter.run(
            'systemctl',
            [if (fixture) '--user', 'stop', testUnit],
          ),
        );
      },
    );
  });
}
