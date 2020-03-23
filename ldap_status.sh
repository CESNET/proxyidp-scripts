#!/bin/bash

# LDAP username
USER=""

# LDAP password
PASSWORD=""

# Base dn of LDAP tree
BASEDN=""

# eduPersonPrincipalName which the script will look for
IDENTITY=""

# List of LDAP HOSTNAMES separated by whitespace
# Each value must start with ldap:// or ldaps://
# For example: "ldaps://hostname.com ldap://hostname.com"
HOSTNAMES=""

for HOSTNAME in $HOSTNAMES
do
    START_TIME=$(date +%s%N)
    if [[ -z $PASSWORD ]]; then
        LDAP_RESULT=$(timeout 10 ldapsearch  -x -H $HOSTNAME -b $BASEDN  "(eduPersonPrincipalNames=$IDENTITY)" 2>&1)
    else
        LDAP_RESULT=$(timeout 10 ldapsearch  -x -H $HOSTNAME -D $USER -w $PASSWORD -b $BASEDN  "(eduPersonPrincipalNames=$IDENTITY)" 2>&1)
    fi
    RESULT=$?
    END_TIME=$(date +%s%N)
    TOTAL_TIME=$(echo "scale=4;$(expr ${END_TIME} - ${START_TIME}) / 1000000000" | bc -l)
    if [[ $RESULT == 0  ]]; then
        echo "0 ldap_status-$HOSTNAME total_time=${TOTAL_TIME} OK"
    else
        echo "2 ldap_status-$HOSTNAME total_time=${TOTAL_TIME} ${LDAP_RESULT}"
    fi
done
