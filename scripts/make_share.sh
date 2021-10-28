#!/bin/sh

set -eu

mkdir "$1"/lua

ln -fs ../init.lua "$1"/init.lua
ln -fs ../../assets "$1"/assets
ln -fs ../../../src "$1"/lua/dovetail

for m in "$2"/*; do
    ln -fs ../../../"$m" "$1"/lua/"${m##*/}"
done
