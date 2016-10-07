#!/usr/bin/env bash

process=App
start="/home/hakon/Subber/.build/debug/App"

if ps ax | grep -v grep | grep $process > /dev/null
then
	exit
else
	$start &
fi

exit

