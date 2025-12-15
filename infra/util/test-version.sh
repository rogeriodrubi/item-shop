#!/usr/bin/env bash

# Params: command version major-min minor-min
command="$1"
which "$command" > /dev/null || { echo "Command not found: $command"; exit 1; }
shift 

version="$(echo "$1" | grep -oE '[0-9]+\.[0-9]+')"

IFS=. read major minor <<< "$version" &&
    test "$major" -gt "$2" -o "$major" -eq "$2" -a "$minor" -ge "$3" ||
    { echo "$command version error: current=$version required=$2.$3"; exit 1; }
