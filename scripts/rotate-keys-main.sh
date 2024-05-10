#!/bin/sh

# https://stackoverflow.com/a/75983637/3208553

args=()
while IFS== read -r k v; do
   args+=("$v")
done < .env

./scripts/rotate-keys-slave.sh "${args[@]}"
