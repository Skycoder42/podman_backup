import 'package:podman_backup/src/backup/backup_job.dart';
import 'package:podman_backup/src/cli/cli_parser.dart';
import 'package:riverpod/riverpod.dart';

Future<void> main(List<String> arguments) async {
  final di = ProviderContainer();
  try {
    final cliParser = di.read(cliParserProvider);
    final options = cliParser.parse(arguments);

    final backupJob = di.read(backupJobProvider);
    await backupJob.run(options);
  } finally {
    di.dispose();
  }
}
