#!/usr/bin/env bash

while getopts "e:f:" opt; do
  	case $opt in
    	e) environment="$OPTARG"
    	;;
     	f) pidFile="$OPTARG"
  	esac
done

if [ -z "$environment" ]; then
  	printf "No environment was provided. Provde one with -e."
  	exit
fi

if [ -z "$pidFile" ]; then
    printf "No pidFile was provided. Provide one with -f."
    exit
fi

sudo rm "$pidFile"
sudo touch "$pidFile"

.build/release/App --env="$environment" & echo $! > "$pidFile"
