#!/usr/bin/env bash

while getopts "e:" opt; do
  	case $opt in
    	e) config="$OPTARG"
    	;;
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

if [[ ! " ${configs[@]} " =~ " ${config} " ]]; then
	printf "Invalid environment. Valid values are "
	printConfigs
	printf "\n"
fi

rm /var/run/instacrated.pid >> /dev/null
touch /var/run/instacrated.pid

echo $(whoami)

vapor run --env="$config" & echo $! >> /var/run/instacrated.pid