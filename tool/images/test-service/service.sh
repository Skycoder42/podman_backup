#!/bin/bash
# $1: name
set -exo pipefail

trap 'echo STOPPED >> /var/log/$1.log' EXIT
echo STARTED >> /var/log/"$1".log

for dir in /mnt/*; do
  out_file=$(mktemp -p "$dir")
  date > "$out_file"
done

sleep infinity
