#!/bin/bash

# List of paths to check separated by space
paths=""

for path in $paths
do
    if [[ -d $path ]]; then
        cd $path
        git fetch origin 2>&1
        localhash=$(git rev-parse HEAD)
        remotehash=$(git rev-parse origin/production)
        if [[ $localhash=$remotehash ]] ; then
            status=0
            statustxt="OK"
        else
            status=1
            statustxt="WARNING - There are available new commits"
        fi
    else
        status=2
        statustxt="CRITICAL - Directory does not exist"
    fi
    echo "$status git_pull_check_dir=$path - $statustxt"
done
