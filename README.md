# podman_backup
[![Continuous integration](https://github.com/Skycoder42/podman_backup/actions/workflows/ci.yaml/badge.svg)](https://github.com/Skycoder42/podman_backup/actions/workflows/ci.yaml)
[![AUR version](https://img.shields.io/aur/version/podman_backup)](https://aur.archlinux.org/packages/podman_backup)

A small dart tool to push regular backups of podman volumes to a remote.

## Table of contents
- [Installation](#installation)
- [Usage](#usage)
  * [How the tool operates](#how-the-tool-operates)
  * [Backup Hooks](#backup-hooks)

<small><i><a href='https://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


## Installation
1. From the AUR (arch package): https://aur.archlinux.org/packages/podman_backup
2. From packagecloud.io (Debian package): https://packagecloud.io/Skycoder42/podman_backup
3. From the releases page: https://github.com/Skycoder42/podman_backup/releases
4. Install as global dart tool: `dart pub global activate podman_backup`
5. Compile it yourself:
   ```bash
   dart pub get
   dart run build_runner build
   dart compile exe bin/podman_backup.dart -o bin/podman-backup
   install bin/podman-backup /usr/local/bin/podman-backup
   ```

In all Variants, after installing you can use the tool from your shell via `podman-backup`

## Usage
```
-r, --remote=<host>               The remote <host> to send the backups to, in the format: [USER@]HOST:DEST. (required)
-b, --backup-mode=<mode>          The mode to run the tool in.

          [backup-only]           Only perform the backup.
          [backup-upload]         Perform backup and upload the backed up files
          [cleanup-only]          Only cleanup old backups on the remote.
          [full] (default)        Perform backup, upload the backed up files and cleanup old backups.
          [upload-cleanup]        Upload the backed up files and cleanup old backups.
          [upload-only]           Only upload previously backed up files.

-l, --backup-label=<label>        The label that volumes should be filtered by to detect which volumes to backup.
                                  (defaults to "de.skycoder42.podman_backup")
-c, --backup-cache=<directory>    The directory to cache backups in before uploading them to the backup host.
                                  (defaults to "/home/vscode/.cache/podman_backup")
    --[no-]user                   Specifies whether systemctl should be invoked as user (by adding "--user" to every
                                  command) or as system. The default is set automatically depending on whether it is
                                  running as root or not.
                                  (defaults to on)
-M, --min-keep=<count>            The minimum number of backups to keep per volume, regardless of all the other cleanup
                                  filters. Must be at least 1.
                                  (defaults to "1")
-K, --max-keep=<count>            The maximum number of backups to keep per volume. Must be at least as much as
                                  --min-keep. If not specified, no limit is applied.
-A, --max-age=<days>              The maximum age (in days) a backup is allowed to be. Older backups will be deleted. If
                                  not specified, no limit is applied.
-S, --max-total-size=<MB>         The maximum total size (in Mega-Bytes) all backups combined are allowed to take up on
                                  the backup device. If this limit is reached, the oldest backups will be deleted. If
                                  not specified, no limit is applied.
-L, --log-level=<level>           Customize the logging level. Listed from most verbose (all) to least verbose (off).
                                  [all, finest, finer, fine, config, info (default), warning, severe, shout, off]
-v, --version                     Prints the current version of the tool.
-h, --help                        Prints usage information.
```

Example: `podman-backup -r backup-user@example.com:/mnt/backups/volumes`

### How the tool operates
The tool itself operates after a simple flow:

1. Determine all volumes to backup
   - This checks for the presence of the backup label on all available volumes
   - Also collects systemd-units for containers that are attached to a volume
2. Build backup strategy
   - Tries to group volumes in a way that they are backed up in small steps while ensuring each service only needs to be
   stopped once and for an as short as possible amount of time
   - Extracts information about backup hooks (more about that later)
3. Execute backup strategy
   - For each group of volumes, stops all attached systemd services
   - Then the volume is backed up using `podman volume export` and compressed
   - Finally, all services are restarted
4. Upload backups to remote server
   - Simply uploads the archives to the remote and deletes them locally afterwards
   - Configure access control in your `.ssh/config`, as the tool is non interactive and thus cannot prompt for
   credentials
5. Deletes old backups on the remote server
   - Runs only if at least one of the 3 cleanup options (-K, -A, -S) are specified
   - Depending on those options (and min-keep), backups that are no longer needed will be deleted

### Backup Hooks
By default, the backup process simply stops attached services, backs up the volume, and then restarts services. However,
sometimes you may want to customize the actual backup of the volume, without loosing the grouping and service control
features of this tool.

This can be done via backup hooks. You can define a hook on a volume by setting the backup label to a non empty string
in the format `[!]unit.service` or `[!]unit@.service`. This will change the backup process in the following ways:

1. The hook must be the name of an existing systemd unit (typically a service). It should be a `Type=oneshot` service,
as the backup will wait for the `systemctl start` command to finish before continuing the backup. Also, the service
will be invoked as user or system service depending on the same rules as all other service invocations (See `--user`
command line flag).
2. If *no* `!` is present as first character, the hook will run as **replacement hook**. This means, it will be run
instead of the normal volume export.
3. If it starts with `!`, the hook will run as **pre hook**, meaning it will be run just before the volume export, but
after attached services have already been stopped. Should the hook fail, then the backup will not continue.
4. It is possible to pass a template unit as hook (`@` before the dot). In that case, the name of the volume is passed
as instance variable to the unit invocation. It will be escaped via
[systemd-escape](https://www.freedesktop.org/software/systemd/man/systemd-escape.html), so make sure to use `%I` (and
not `%i`) when using the instance variable within your service.
