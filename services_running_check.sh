#!/bin/bash

# List of service names separated by space
services=""

for service in $services
do
    serviceStatusResult=$(service $service status -v 2> /dev/null)
    IFS=$'\n'
    re="Active:.*"
    reActive="Active: active \(running\)"
    reStopped="Active: inactive \(dead\)"

    if [[ -n $serviceStatusResult ]] ; then

        for item in $serviceStatusResult
        do
            if [[ $item =~ $re ]]; then
                serviceStatus=$item
                break
            fi
        done

        if [[ $serviceStatus =~ $reActive ]]; then
            status=0
            statustxt="Service $service is running."
        else
            if [[ $serviceStatus =~ $reStopped ]]; then
                status=2
                statustxt="Service $service is stopped."
            else
                status=2
                statustxt="Service $service is in unknown state: $serviceStatus"
            fi
        fi
    else
        status=2
        statustxt="Service $service doesn't exist"
    fi

    echo "$status service_running_check_$service - $statustxt"
done