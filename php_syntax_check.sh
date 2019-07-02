#!/bin/bash

#The root directory to check
dir="/etc/simplesamlphp"

cd $dir

paths=$(find . -type f -name "*.php")
globalResult=""

for path in $paths
do
    if [[ -f $path ]] ; then
        result=$(php -l $path 2>&1)
        if [[ ! $result =~ ^No.syntax.errors.*$ ]] ; then
            globalResult+="$result  |  "
        fi
    fi
done

if [[ -z $globalResult ]] ; then
    echo "0 php_syntax_check - OK"
else
    echo "2 php_syntax_check - $globalResult"
fi
