#!/bin/bash
set -exo pipefail

trap 'echo STOPPED >> /var/log/test-service.log' EXIT
echo STARTED >> /var/log/test-service.log

for dir in /mnt/*; do
  out_file=$(mktemp -p "$dir")
  date > "$out_file"
done

sleep infinity
