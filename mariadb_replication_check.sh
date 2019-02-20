#!/bin/bash

USER="Nagios"
PASSWD="]pS+0#zbdMUpD7-r>C"
# Addresses in quotes separated by spaces ("add1" "add2" "add3")
machines=()
machinesCount=${#machines[*]}

for i in $(seq 0 $(expr $machinesCount - 1)); do
    result[i]=$(mysql -u ${USER} -p${PASSWD} -h ${machines[i]} --execute="SHOW STATUS LIKE 'wsrep_last_committed';" 2> /dev/null | tr -dc '0-9')
done

for i in $(seq 0 $(expr $machinesCount - 1)); do
    if [[ -z ${result[i]} ]]; then
        echo "2 mariadb_replication_check - ${machines[i]}: An error appeared while connecting mariadb."
        exit
    fi
done

for i in $(seq 0 $(expr $machinesCount - 2)); do
    if [[ ${result[i]} -ne ${result[i+1]} ]]; then
        echo "2 mariadb_replication_check - The result from ${machines[1]} (${result[i]}) is not equal to the result from ${machines[i+1]} (${result[i+1]})"
        exit
    fi
done

echo "0 mariadb_replication_check - OK"
