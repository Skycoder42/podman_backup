#!/bin/bash
set -eo pipefail

echo ::group::Install podman
sudo apt-get update
sudo apt-get install -y podman fuse-overlayfs
echo ::endgroup::

echo ::group::Install and start systemd test units
pushd tool/units
install -Dt "$HOME/.config/systemd/user/" -m 644 -- *.service
systemctl --user daemon-reload
systemctl --user start -- *.service
popd
echo ::endgroup::

echo ::group::Setup SSH
sudo systemctl start sshd.service

mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519

ssh-keyscan 127.0.0.1 > ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts

cat ~/.ssh/id_ed25519.pub > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "Host integration_test_local
    HostName 127.0.0.1
    User $USER
    IdentityFile ~/.ssh/id_ed25519
" > ~/.ssh/config
chmod 600 ~/.ssh/config
echo ::endgroup::
