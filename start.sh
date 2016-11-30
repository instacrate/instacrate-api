#!/bin/bash

while getopts "e:f:" opt; do
  	case $opt in
    	e) config="$OPTARG"
    	;;
      f) pidFile="$OPTARG"
  	esac
done

configs=("development" "production" "staging")

function printConfigs {
	for item in ${configs[*]}; do
    	printf "%s " "$item"
	done
}

if [ -z "$config" ]; then
  	printf "No environment was provided. Provde one with -e. Valid values are "
  	printConfigs
  	printf "\n"
  	exit
fi

if [ -z "$pidFile" ]; then
    printf "No pidFile was provided."
    exit
fi

if [[ ! " ${configs[@]} " =~ " ${config} " ]]; then
	printf "Invalid environment. Valid values are "
	printConfigs
	printf "\n"
fi

sudo rm "$pidFile"
sudo touch "$pidFile"

/usr/local/bin/vapor run --env="$config" & echo $! > "$pidFile"