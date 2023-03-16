#!/bin/sh
# $1: name
set -ex

for dir in /mnt/*; do
  out_file=$(mktemp -p "$dir")
  date > "$out_file"
done

sleep infinity
