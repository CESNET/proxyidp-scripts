#!/bin/bash

# This script is used make a full roundtrip login test to OIDC SP
# Exit statuses indicate problem and are suitable for usage in Nagios.
# @author Pavel Vyskocil <Pavel.Vyskocil@cesnet.cz>

DIR="${0%/*}"
SCRIPT_DIR="${DIR}/proxy_idp_auth_test_script"

BASENAME=$(basename "$0")

AAI_TEST_SITE=${1}
AAI_LOGIN_SITE=${2}
AAI_LOGIN=${3}
AAI_PASSWORD=${4}
MUNI_TEST_SITE=${5}
MUNI_LOGIN_SITE=${6}
MUNI_LOGIN=${7}
MUNI_PASSWORD=${8}
CESNET_TEST_SITE=${9}
CESNET_LOGIN_SITE=${10}
CESNET_LOGIN=${11}
CESNET_PASSWORD=${12}
WARNING_TIME=${13}
TIMEOUT_TIME=${14}

AAI_LOGIN_CMD="$SCRIPT_DIR/oidc_auth_test_aai_active.sh ${AAI_TEST_SITE} ${AAI_LOGIN_SITE} ${AAI_LOGIN} ${AAI_PASSWORD}"
MUNI_LOGIN_CMD="$SCRIPT_DIR/oidc_auth_test_muni_active.sh ${MUNI_TEST_SITE} ${MUNI_LOGIN_SITE} ${MUNI_LOGIN} ${MUNI_PASSWORD}"
CESNET_LOGIN_CMD="$SCRIPT_DIR/oidc_auth_test_cesnet_active.sh ${CESNET_TEST_SITE} ${CESNET_LOGIN_SITE} ${CESNET_LOGIN} ${CESNET_PASSWORD}"


# Test sign in with AAI Playground IdP
START_TIME=$(date +%s%N)
AAI_RESULT=$(timeout ${TIMEOUT_TIME} ${AAI_LOGIN_CMD})
AAI_RC=$?
END_TIME=$(date +%s%N)
if [ ${AAI_RC} -gt 2 ]; then
  AAI_RC=2
  AAI_RESULT="Login with AAI account timeouted after ${TIMEOUT_TIME}s!"
fi
AAI_TOTAL_TIME=$(expr ${END_TIME} - ${START_TIME})
AAI_LOGIN_TIME=$(echo "scale=4;${AAI_TOTAL_TIME} / 1000000000" | bc -l)

# Signing in with AAI account was successful. Returning OK.
if [ ${AAI_RC} -eq 0 ]; then
    if [ ${AAI_TOTAL_TIME} -gt $(( WARNING_TIME * 1000000000 )) ];then
        STATUS=1
        STATUS_TXT="Successful login, but was too long(More than ${WARNING_TIME}s)!"
    else
        STATUS=0
        STATUS_TXT="Successful login!"
    fi

    RESULT="OIDC Auth test active - ${STATUS_TXT} [AAI STATUS - ${AAI_RESULT}(${AAI_LOGIN_TIME}s); MUNI STATUS - Not tried; CESNET STATUS - Not tried] | aai_login_time=${AAI_LOGIN_TIME} muni_login_time=0 cesnet_login_time=0"
    echo ${RESULT}
    exit ${STATUS}
fi


# Test sign in with MUNI IdP
START_TIME=$(date +%s%N)
MUNI_RESULT=$(timeout ${TIMEOUT_TIME} ${MUNI_LOGIN_CMD})
MUNI_RC=$?
END_TIME=$(date +%s%N)
if [ ${MUNI_RC} -gt 2 ]; then
  MUNI_RC=2
  MUNI_RESULT="Login with MUNI account timeouted after ${TIMEOUT_TIME}s!"
fi
MUNI_TOTAL_TIME=$(expr ${END_TIME} - ${START_TIME})
MUNI_LOGIN_TIME=$(echo "scale=4;${MUNI_TOTAL_TIME} / 1000000000" | bc -l)


# Signing in with MUNI account was successful. Returning OK.
if [ ${MUNI_RC} -eq 0 ]; then
    if [ ${MUNI_TOTAL_TIME} -gt $(( WARNING_TIME * 1000000000 )) ];then
        STATUS=1
        STATUS_TXT="Successful login, but was too long(More than ${WARNING_TIME}s)!"
    else
        STATUS=0
        STATUS_TXT="Successful login!"
    fi

    RESULT="OIDC Auth test active - ${STATUS_TXT} [AAI STATUS - ${AAI_RESULT}(${AAI_LOGIN_TIME}s); MUNI STATUS - ${MUNI_RESULT}(${MUNI_LOGIN_TIME}s); CESNET STATUS - Not tried] | aai_login_time=${AAI_LOGIN_TIME} muni_login_time=${MUNI_LOGIN_TIME} cesnet_login_time=0"
    echo ${RESULT}
    exit ${STATUS}
fi

# Test sign in with CESNET IdP
START_TIME=$(date +%s%N)
CESNET_RESULT=$(timeout ${TIMEOUT_TIME} ${CESNET_LOGIN_CMD})
CESNET_RC=$?
END_TIME=$(date +%s%N)

if [ ${CESNET_RC} -gt 2 ]; then
  CESNET_RC=2
  CESNET_RESULT="Login with CESNET account timeouted after ${TIMEOUT_TIME}s!"
fi
CESNET_TOTAL_TIME=$(expr ${END_TIME} - ${START_TIME})
CESNET_LOGIN_TIME=$(echo "scale=4;${CESNET_TOTAL_TIME} / 1000000000" | bc -l)

if [ ${CESNET_RC} -eq 0 ]; then
    if [ ${CESNET_TOTAL_TIME} -gt $(( WARNING_TIME * 1000000000 )) ];then
        STATUS=1
        STATUS_TXT="Successful login, but was too long(More than ${WARNING_TIME}s)!"
    else
        STATUS=0
        STATUS_TXT="Successful login!"
    fi
else
    STATUS=2
    STATUS_TXT="Unsuccessful login!"
fi

RESULT="OIDC Auth test active - ${STATUS_TXT} [AAI STATUS - ${AAI_RESULT}(${AAI_LOGIN_TIME}s); MUNI STATUS - ${MUNI_RESULT}(${MUNI_LOGIN_TIME}s); CESNET STATUS - ${CESNET_RESULT}(${CESNET_LOGIN_TIME}] | aai_login_time=${AAI_LOGIN_TIME} muni_login_time=${MUNI_LOGIN_TIME} cesnet_login_time=${CESNET_LOGIN_TIME}"
echo ${RESULT}
exit ${STATUS}
