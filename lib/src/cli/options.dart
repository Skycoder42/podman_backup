import 'dart:io';

import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:meta/meta.dart';

part 'options.g.dart';

@CliOptions()
@immutable
class Options {
  @CliOption(
    name: 'remote',
    abbr: 'r',
    valueHelp: 'host',
    help: 'The remote <host> to send the backups to. (Required)',
  )
  final String? remoteHost;
  final bool remoteHostWasParsed;

  @CliOption(
    abbr: 'l',
    defaultsTo: 'de.skycoder42.podman_backup',
    valueHelp: 'label',
    help: 'The label that volumes should be filtered by '
        'to detect which volumes to backup.',
  )
  final String backupLabel;

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
    required this.backupLabel,
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
