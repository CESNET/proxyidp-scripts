#!/bin/bash

# RPC username
USER=""

# RPC password
PASSWORD=""

# RPC domain with authentication method
# Example: "perun.cesnet.cz/krb"
DOMAIN=""

# Valid userId - This id will be used in getUserById call
USER_ID=""

URL="https://${DOMAIN}/rpc/json/usersManager/getUserById?id=${USER_ID}"

START_TIME=$(date +%s%N)
RPC_RESULT=$(timeout 10 curl --user ${USER}:${PASSWORD} ${URL} 2>&1)
END_TIME=$(date +%s%N)
TOTAL_TIME=$(echo "scale=4;$(expr ${END_TIME} - ${START_TIME}) / 1000000000" | bc -l)
if [[ $RPC_RESULT == *\"id\":${USER_ID}*  ]]; then
    echo "0 rpc_status total_time=${TOTAL_TIME} OK"
else
    echo "2 rpc_status total_time=${TOTAL_TIME} ${RPC_RESULT}"
fi
