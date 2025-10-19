import 'dart:io';

import 'package:logging/logging.dart';
import 'package:podman_backup/src/cli/cli_parser.dart';
import 'package:podman_backup/src/di/dependencies.dart';
import 'package:podman_backup/src/podman_backup.dart';

Future<void> main(List<String> arguments) async {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(stdout.writeln);

  final di = createDiContainer();
  try {
    final cliParser = di.get<CliParser>();
    final options = cliParser.parse(arguments);
    di.pushNewScope(init: (di) => di.registerSingleton(options), isFinal: true);

    final backupJob = di.get<PodmanBackup>();
    await backupJob.run();
  } finally {
    await di.reset();
  }
}
