#!/bin/sh

set -eu

ln -fs ../init.lua "$1"/init.lua
ln -fs ../../src "$1"/dovetail

for m in "$2"/*; do
    ln -fs ../../"$m" "$1/${m##*/}"
done
