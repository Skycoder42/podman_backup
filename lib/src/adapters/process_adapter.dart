import 'dart:convert';
import 'dart:io';

import 'package:riverpod/riverpod.dart';

// coverage:ignore-start
final processAdapterProvider = Provider(
  (ref) => ProcessAdapter(stderr),
);
// coverage:ignore-end

class ProcessFailed implements Exception {
  final String executable;
  final List<String> arguments;
  final int exitCode;

  ProcessFailed(this.executable, this.arguments, this.exitCode);

  // coverage:ignore-start
  @override
  String toString() => 'ProcessFailed: $executable ${arguments.join(' ')} '
      'failed with exit code $exitCode';
  // coverage:ignore-end
}

class ProcessAdapter {
  final IOSink _stderr;

  ProcessAdapter(this._stderr);

  Stream<Object?> streamJson(
    String executable,
    List<String> arguments, {
    int? expectedExitCode = 0,
  }) async* {
    final proc = await Process.start(
      executable,
      arguments,
    );

    final stderrSub = proc.stderr
        .transform(systemEncoding.decoder)
        .transform(const LineSplitter())
        .listen(_stderr.writeln);
    try {
      yield* proc.stdout
          .transform(systemEncoding.decoder)
          .transform(json.decoder);

      if (expectedExitCode != null) {
        final exitCode = await proc.exitCode;
        if (exitCode != expectedExitCode) {
          throw ProcessFailed(executable, arguments, exitCode);
        }
      }
    } finally {
      await stderrSub.cancel();
    }
  }
}
