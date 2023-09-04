// coverage:ignore-file

import 'dart:io';

import 'package:build_cli_annotations/build_cli_annotations.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../adapters/environment_adapter.dart';
import '../adapters/posix_adapter.dart';

part 'options.g.dart';

enum BackupMode {
  full,
  backupUpload,
  uploadCleanup,
  backupOnly,
  uploadOnly,
  cleanupOnly;
}

extension BackupModeX on BackupMode {
  bool get backup =>
      this == BackupMode.full ||
      this == BackupMode.backupUpload ||
      this == BackupMode.backupOnly;

  bool get upload =>
      this == BackupMode.full ||
      this == BackupMode.backupUpload ||
      this == BackupMode.uploadCleanup ||
      this == BackupMode.uploadOnly;

  bool get cleanup =>
      this == BackupMode.full ||
      this == BackupMode.uploadCleanup ||
      this == BackupMode.cleanupOnly;
}

@CliOptions()
@immutable
class Options {
  static const defaultBackupLabel = 'de.skycoder42.podman_backup';

  @CliOption(
    name: 'remote',
    abbr: 'r',
    valueHelp: 'host',
    help: 'The remote <host> to send the backups to, '
        'in the format: [USER@]HOST:DEST. (required)',
  )
  @internal
  final String? remoteHostRaw;
  final bool remoteHostRawWasParsed;

  @CliOption(
    abbr: 'b',
    defaultsTo: BackupMode.full,
    valueHelp: 'mode',
    help: 'The mode to run the tool in.',
    allowedHelp: {
      BackupMode.full:
          'Perform backup, upload the backed up files and cleanup old backups.',
      BackupMode.backupUpload: 'Perform backup and upload the backed up files',
      BackupMode.uploadCleanup:
          'Upload the backed up files and cleanup old backups.',
      BackupMode.backupOnly: 'Only perform the backup.',
      BackupMode.uploadOnly: 'Only upload previously backed up files.',
      BackupMode.cleanupOnly: 'Only cleanup old backups on the remote.',
    },
  )
  final BackupMode backupMode;

  @CliOption(
    abbr: 'l',
    defaultsTo: Options.defaultBackupLabel,
    valueHelp: 'label',
    help: 'The label that volumes should be filtered by '
        'to detect which volumes to backup.',
  )
  final String backupLabel;

  @CliOption(
    convert: _directoryFromString,
    abbr: 'c',
    valueHelp: 'directory',
    provideDefaultToOverride: true,
    help: 'The directory to cache backups in before uploading them to '
        'the backup host.',
  )
  final Directory backupCache;

  @CliOption(
    negatable: true,
    provideDefaultToOverride: true,
    help: 'Specifies whether systemctl should be invoked as user '
        '(by adding "--user" to every command) or as system. The default is '
        'set automatically depending on whether it is running as root or not.',
  )
  final bool user;

  @CliOption(
    convert: _logLevelFromString,
    abbr: 'L',
    allowed: [
      'all',
      'finest',
      'finer',
      'fine',
      'config',
      'info',
      'warning',
      'severe',
      'shout',
      'off',
    ],
    defaultsTo: 'info',
    valueHelp: 'level',
    help: 'Customize the logging level. '
        'Listed from most verbose (all) to least verbose (off).',
  )
  final Level logLevel;

  @CliOption(
    abbr: 'v',
    negatable: false,
    defaultsTo: false,
    help: 'Prints the current version of the tool.',
  )
  final bool version;

  @CliOption(
    abbr: 'h',
    negatable: false,
    defaultsTo: false,
    help: 'Prints usage information.',
  )
  final bool help;

  const Options({
    required this.remoteHostRaw,
    required this.remoteHostRawWasParsed,
    this.backupMode = BackupMode.full,
    this.backupLabel = Options.defaultBackupLabel,
    required this.backupCache,
    required this.user,
    this.logLevel = Level.INFO,
    this.version = false,
    this.help = false,
  });

  String getRemoteHost() => remoteHostRaw!;

  static ArgParser buildArgParser(
    EnvironmentAdapter environmentAdapter,
    PosixAdapter posixAdapter,
  ) =>
      _$populateOptionsParser(
        ArgParser(
          allowTrailingOptions: false,
          usageLineLength: stdout.hasTerminal ? stdout.terminalColumns : null,
        ),
        backupCacheDefaultOverride: _backupDir(environmentAdapter).path,
        userDefaultOverride: !posixAdapter.isRoot,
      );

  static Options parseOptions(ArgResults argResults) =>
      _$parseOptionsResult(argResults);

  static Directory _backupDir(EnvironmentAdapter environmentAdapter) {
    final home = environmentAdapter['HOME'];
    if (home != null) {
      return Directory('$home/.cache/podman_backup');
    }

    return Directory.fromUri(
      Directory.systemTemp.uri.resolve('podman_backup'),
    );
  }
}

Level _logLevelFromString(String level) =>
    Level.LEVELS.singleWhere((element) => element.name == level.toUpperCase());

Directory _directoryFromString(String directory) => Directory(directory);
