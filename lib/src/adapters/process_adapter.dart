import 'dart:async';
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

  Future<int> run(
    String executable,
    List<String> arguments, {
    int? expectedExitCode = 0,
  }) async {
    final proc = await Process.start(
      executable,
      arguments,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await proc.exitCode;
    if (expectedExitCode != null) {
      if (exitCode != expectedExitCode) {
        throw ProcessFailed(executable, arguments, exitCode);
      }
    }

    return exitCode;
  }

  Stream<List<int>> streamRaw(
    String executable,
    List<String> arguments, {
    int? expectedExitCode = 0,
    Stream<List<int>>? stdin,
  }) async* {
    final proc = await Process.start(
      executable,
      arguments,
    );

    Future<void>? stdinPipeDone;
    if (stdin != null) {
      stdinPipeDone = stdin.pipe(proc.stdin);
    }

    final stderrSub = proc.stderr
        .transform(systemEncoding.decoder)
        .transform(const LineSplitter())
        .listen(_stderr.writeln);

    try {
      yield* proc.stdout;

      await stdinPipeDone;

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

  Stream<Object?> streamJson(
    String executable,
    List<String> arguments, {
    int? expectedExitCode = 0,
  }) =>
      streamRaw(executable, arguments, expectedExitCode: expectedExitCode)
          .transform(systemEncoding.decoder)
          .transform(json.decoder);
}
