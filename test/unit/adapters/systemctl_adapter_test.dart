import 'package:dart_test_tools/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:podman_backup/src/adapters/process_adapter.dart';
import 'package:podman_backup/src/adapters/systemctl_adapter.dart';
import 'package:podman_backup/src/cli/options.dart';
import 'package:test/test.dart';

class MockProcessAdapter extends Mock implements ProcessAdapter {}

class FakeOptions extends Fake implements Options {
  @override
  final bool user;

  // ignore: avoid_positional_boolean_parameters
  FakeOptions(this.user);
}

void main() {
  group('$SystemctlAdapter', () {
    final mockProcessAdapter = MockProcessAdapter();

    // ignore: avoid_positional_boolean_parameters
    SystemctlAdapter createSut(bool runAsUser) =>
        SystemctlAdapter(mockProcessAdapter, FakeOptions(runAsUser));

    setUp(() {
      reset(mockProcessAdapter);

      when(() => mockProcessAdapter.run(any(), any())).thenReturnAsync(0);
    });

    testData<bool>('start invokes systemd start', const [true, false], (
      fixture,
    ) async {
      const testUnit = 'test.service';
      final sut = createSut(fixture);

      await sut.start(testUnit);

      verify(
        () => mockProcessAdapter.run('systemctl', [
          if (fixture) '--user',
          'start',
          testUnit,
        ]),
      );
    });

    testData<bool>('stop invokes systemd stop', const [true, false], (
      fixture,
    ) async {
      const testUnit = 'test.service';
      final sut = createSut(fixture);

      await sut.stop(testUnit);

      verify(
        () => mockProcessAdapter.run('systemctl', [
          if (fixture) '--user',
          'stop',
          testUnit,
        ]),
      );
    });

    group('escape', () {
      test('invokes systemd-escape', () async {
        const template = 'test-template';
        const value = 'test-value';
        const escaped = 'test-escaped';
        when(
          () => mockProcessAdapter.streamLines(any(), any()),
        ).thenStream(Stream.value(escaped));

        final sut = createSut(false);
        final result = await sut.escape(template: template, value: value);

        expect(result, escaped);
        verify(
          () => mockProcessAdapter.streamLines('systemd-escape', [
            '--template',
            template,
            value,
          ]),
        );
      });

      test('throws if result is not a single value stream', () {
        const template = 'test-template';
        const value = 'test-value';
        when(
          () => mockProcessAdapter.streamLines(any(), any()),
        ).thenStream(Stream.fromIterable(['a', 'b']));

        final sut = createSut(false);

        expect(
          () => sut.escape(template: template, value: value),
          throwsA(isStateError),
        );
      });
    });
  });
}
