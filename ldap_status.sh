#!/bin/bash

# LDAP username
user=""

# LDAP password
password=""

# Base dn of LDAP tree
basedn=""

# eduPersonPrincipalName which will be searched
searchedIdentity=""

# List of LDPA hostnames separated by space
# Included ldap:// or ldaps://
hostnames=""

for hostname in $hostnames
do
    if [[ -z $password ]]; then
        ldapresult=$(ldapsearch  -x -H $hostname -b $basedn  "(eduPersonPrincipalNames=$searchedIdentity)" 2>&1)
    else
        ldapresult=$(ldapsearch  -x -H $hostname -D $user -w $password -b $basedn  "(eduPersonPrincipalNames=$searchedIdentity)" 2>&1)
    fi
    result=$?
    if [[ $result == 0  ]]; then
        echo "0 ldap_status-$hostname - OK"
    else
        echo "2 ldap_status-$hostname - $ldapresult"
    fi
done
