// coverage:ignore-file

import 'package:posix/posix.dart' as posix;
import 'package:riverpod/riverpod.dart';

final posixAdapterProvider = Provider((ref) => PosixAdapter());

class PosixAdapter {
  bool get isRoot => _ifSupported(() => posix.geteuid() == 0) ?? false;

  T? _ifSupported<T>(T Function() action) =>
      posix.isPosixSupported ? action() : null;
}
