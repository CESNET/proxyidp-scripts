#!/bin/bash

# This script is used make a full roundtrip login test to SAML SP
# Exit statuses indicate problem and are suitable for usage in Nagios.
# @author Pavel Vyskocil <Pavel.Vyskocil@cesnet.cz>

DIR="${0%/*}"
source "${DIR}/proxy_idp_auth_test_config.sh"

CACHE_FILE=${DIR}/proxy_idp_auth_test_saml.cache

if [[ $1 == "-f" ]]; then
    FORCE=0
else
    FORCE=1
fi

if [[ -f "$CACHE_FILE" ]]; then
  CACHE_LAST_MODIFIED=$(($(date +%s) - $(date +%s -r ${CACHE_FILE})))
  REGEX_CHECK=$(grep -c '\d proxy_idp_auth_test_saml.sh.*muni_login_time.*cesnet_login_time.*MUNI STATUS.*CESNET STATUS' ${CACHE_FILE})

  if [[ ${CACHE_LAST_MODIFIED} -le ${CACHE_TIME} && $(wc -l <${CACHE_FILE}) -eq 1 && ${REGEX_CHECK} -eq 0 && ${FORCE} -ne 0 ]]; then
    echo "$(<${CACHE_FILE})"
    exit 0
  fi
fi

BASENAME=$(basename "$0")
WARNING_TIME=${SAML_WARNING_TIME}

SCRIPT_DIR="${DIR}/proxy_idp_auth_test_script"

MUNI_LOGIN_CMD="$SCRIPT_DIR/saml_auth_test_muni.sh ${MUNI_SAML_TEST_SITE} ${MUNI_LOGIN_SITE} ${MUNI_LOGIN} ${MUNI_PASSWORD} ${PROXY_DOMAIN_NAME}"
CESNET_LOGIN_CMD="$SCRIPT_DIR/saml_auth_test_cesnet.sh ${CESNET_SAML_TEST_SITE} ${CESNET_LOGIN_SITE} ${CESNET_LOGIN} ${CESNET_PASSWORD} ${PROXY_DOMAIN_NAME}"

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

RESULT="${STATUS} ${BASENAME}-${INSTANCE_NAME} muni_login_time=${MUNI_LOGIN_TIME}|cesnet_login_time=${CESNET_LOGIN_TIME} ${STATUS_TXT} [MUNI STATUS - ${MUNI_RESULT}(${MUNI_LOGIN_TIME}s); CESNET STATUS - ${CESNET_RESULT}(${CESNET_LOGIN_TIME}s)]"

echo ${RESULT}
echo ${RESULT} > ${DIR}/proxy_idp_auth_test_saml.cache
exit 0
