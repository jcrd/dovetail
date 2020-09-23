#!/bin/sh

set -eu

while IFS=' ' read -r name ver; do
    luarocks --tree "$1" install --deps-mode none "$name" "$ver"
done < rock_versions
