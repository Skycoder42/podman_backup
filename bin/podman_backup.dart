import 'dart:io';

import 'package:logging/logging.dart';
import 'package:podman_backup/src/cli/cli_parser.dart';
import 'package:podman_backup/src/podman_backup.dart';
import 'package:riverpod/riverpod.dart';

Future<void> main(List<String> arguments) async {
  Logger.root
    ..level = Level.ALL
    ..onRecord.listen(stdout.writeln);

  final di = ProviderContainer();
  try {
    final cliParser = di.read(cliParserProvider);
    final options = cliParser.parse(arguments);

    final backupJob = di.read(podmanBackupProvider);
    await backupJob.run(options);
  } finally {
    di.dispose();
  }
}
