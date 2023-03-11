import 'dart:io';

import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:meta/meta.dart';

part 'options.g.dart';

enum BackupMode {
  full,
  backupOnly,
  uploadOnly;
}

@CliOptions()
@immutable
class Options {
  @CliOption(
    name: 'remote',
    abbr: 'r',
    valueHelp: 'host',
    help: 'The remote <host> to send the backups to. (required)',
  )
  final String? remoteHost;
  final bool remoteHostWasParsed;

  @CliOption(
    abbr: 'b',
    defaultsTo: BackupMode.full,
    valueHelp: 'mode',
    help: 'The mode to run the tool in.',
    allowedHelp: {
      BackupMode.full: 'Perform backup and upload the backed up files.',
      BackupMode.backupOnly: 'Only perform the backup.',
      BackupMode.uploadOnly: 'Only upload previously backed up files.',
    },
  )
  final BackupMode backupMode;

  @CliOption(
    abbr: 'l',
    defaultsTo: 'de.skycoder42.podman_backup',
    valueHelp: 'label',
    help: 'The label that volumes should be filtered by '
        'to detect which volumes to backup.',
  )
  final String backupLabel;

  @CliOption(
    abbr: 'c',
    valueHelp: 'directory',
    help: 'The directory to cache backups in before uploading them to '
        'the backup host.\n(defaults to "~/.cache/podman_backup")',
  )
  final String? backupCache;

  @CliOption(
    abbr: 'h',
    negatable: false,
    defaultsTo: false,
    help: 'Prints usage information.',
  )
  final bool help;

  const Options({
    required this.remoteHost,
    this.remoteHostWasParsed = false,
    required this.backupMode,
    required this.backupLabel,
    this.backupCache,
    this.help = false,
  });

  static ArgParser buildArgParser() => _$populateOptionsParser(
        ArgParser(
          allowTrailingOptions: false,
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        ),
      );

  static Options parseOptions(ArgResults argResults) =>
      _$parseOptionsResult(argResults);
}
