#!/bin/bash

# List of paths to check separated by space
paths=""

for path in $paths
do
    if [[ -d $path ]]; then
        cd $path
        $(git fetch origin 2>&1)
        result=$(git diff --name-only origin/production 2>&1)
        if [[ -n $result ]] ; then
            status=1
            statustxt="WARNING - There are available new commits"
        else
            status=0
            statustxt="OK"
        fi
    else
        status=2
        statustxt="CRITICAL - Directory does not exist"
    fi
    echo "$status git_pull_check_dir=$path - $statustxt"
done
