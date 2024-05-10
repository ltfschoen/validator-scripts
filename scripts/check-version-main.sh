#!/bin/sh

while :; do
  /root/check-version-slave.sh
  sleep 86400 # sleep for one day
done
