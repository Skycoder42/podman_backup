#!/bin/sh
# $1: name
set -ex

trap 'echo "STOPPED $1" >> /var/log/test-service.log' TERM
echo "STARTED $1" >> /var/log/test-service.log

for dir in /mnt/*; do
  out_file=$(mktemp -p "$dir")
  date > "$out_file"
done

sleep infinity
