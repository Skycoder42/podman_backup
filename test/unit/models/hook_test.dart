import 'package:dart_test_tools/test.dart';
import 'package:podman_backup/src/models/hook.dart';
import 'package:test/test.dart';

void main() {
  group('$Hook', () {
    group('parse', () {
      test('throws exception if not a hook', () {
        expect(
          () => Hook.parse('invalid value'),
          throwsA(
            isFormatException.having(
              (m) => m.source,
              'source',
              'invalid value',
            ),
          ),
        );
      });

      testData<(String, Hook)>(
        'correctly parses hooks',
        const [
          ('test.service', Hook(unit: 'test', type: 'service')),
          ('test.service.timer', Hook(unit: 'test.service', type: 'timer')),
          ('test.container', Hook(unit: 'test', type: 'container')),
          (
            'test@.service',
            Hook(unit: 'test', type: 'service', isTemplate: true)
          ),
          ('!test.service', Hook(unit: 'test', type: 'service', preHook: true)),
          (
            '!test.service@.container',
            Hook(
              unit: 'test.service',
              type: 'container',
              isTemplate: true,
              preHook: true,
            )
          ),
          (
            'test!my@service.service',
            Hook(unit: 'test!my@service', type: 'service')
          ),
        ],
        (fixture) {
          final hook = Hook.parse(fixture.$1);
          expect(hook, fixture.$2);
        },
      );
    });
  });
}
