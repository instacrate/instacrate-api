#!/usr/bin/env bash

if ! mkdir /tmp/subber_api.lock; then
	printf "Failed to aquire lock.\n" >&2
	exit 1
fi
trap 'rm -rf /tmp/subber_api.lock' EXIT

sudo /home/hakon/Subber/.build/debug/App > /home/hakon/Subber/subber.log
