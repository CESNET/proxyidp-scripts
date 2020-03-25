#!/bin/bash

# This script is used make a full roundtrip login test to OIDC SP
# Exit statuses indicate problem and are suitable for usage in Nagios.
# @author Pavel Vyskocil <Pavel.Vyskocil@cesnet.cz>

DIR="${0%/*}"
SCRIPT_DIR="${DIR}/proxy_idp_auth_test_script"

BASENAME=$(basename "$0")

MUNI_TEST_SITE=${1}
MUNI_LOGIN_SITE=${2}
MUNI_LOGIN=${3}
MUNI_PASSWORD=${4}
CESNET_TEST_SITE=${5}
CESNET_LOGIN_SITE=${6}
CESNET_LOGIN=${7}
CESNET_PASSWORD=${8}
WARNING_TIME=${9}
TIMEOUT_TIME=${10}

MUNI_LOGIN_CMD="$SCRIPT_DIR/oidc_auth_test_muni_active.sh ${MUNI_TEST_SITE} ${MUNI_LOGIN_SITE} ${MUNI_LOGIN} ${MUNI_PASSWORD}"
CESNET_LOGIN_CMD="$SCRIPT_DIR/oidc_auth_test_cesnet_active.sh ${CESNET_TEST_SITE} ${CESNET_LOGIN_SITE} ${CESNET_LOGIN} ${CESNET_PASSWORD}"

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

if [[ ${MUNI_RC} -eq 0 || ${CESNET_RC} -eq 0 ]]; then
  if [[ ${MUNI_TOTAL_TIME} -gt $(( WARNING_TIME * 1000000000 )) && ${CESNET_TOTAL_TIME} -gt $(( WARNING_TIME * 1000000000 )) ]];then
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


echo "OIDC Auth test active - ${STATUS_TXT} [MUNI STATUS - ${MUNI_RESULT}(${MUNI_LOGIN_TIME}s); CESNET STATUS - ${CESNET_RESULT}(${CESNET_LOGIN_TIME}s)] | muni_login_time=${MUNI_LOGIN_TIME} cesnet_login_time=${CESNET_LOGIN_TIME}"
exit ${STATUS}
