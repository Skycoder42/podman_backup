# podman_backup
[![Continuous integration](https://github.com/Skycoder42/podman_backup/actions/workflows/ci.yaml/badge.svg)](https://github.com/Skycoder42/podman_backup/actions/workflows/ci.yaml)
[![AUR version](https://img.shields.io/aur/version/podman_backup)](https://aur.archlinux.org/packages/podman_backup)

A small dart tool to push regular backups of podman volumes to a remote.


## Installation
1. From the AUR: https://aur.archlinux.org/packages/podman_backup
2. From the releases page: https://github.com/Skycoder42/podman_backup/releases
3. Install as global dart tool: `dart pub global activate podman_backup`
4. Compile it yourself:
   ```bash
   dart pub get
   dart run build_runner build
   dart compile exe bin/podman_backup.dart -o bin/podman-backup
   install bin/podman-backup /usr/local/bin/podman-backup
   ```

In all Variants, after installing you can use the tool from your shell via `podman-backup`

## Usage
TODO
