import 'package:podman_backup/src/adapters/date_time_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('$DateTimeAdapter', () {
    late DateTimeAdapter sut;

    setUp(() {
      sut = DateTimeAdapter();
    });

    test('now returns DateTime.now', () {
      final expected = DateTime.now();
      final actual = sut.now;

      expect(
        actual.millisecondsSinceEpoch,
        closeTo(expected.millisecondsSinceEpoch, 10),
      );
    });

    test('utcNow returns DateTime.now as UTC', () {
      final expected = DateTime.now().toUtc();
      final actual = sut.utcNow;

      expect(
        actual.millisecondsSinceEpoch,
        closeTo(expected.millisecondsSinceEpoch, 10),
      );
    });
  });
}
