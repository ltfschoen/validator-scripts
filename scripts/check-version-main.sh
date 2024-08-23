#!/bin/sh

while :; do
  $(dirname "$0")/check-version-slave.sh
  sleep 86400 # sleep for one day
done
