#!/bin/bash
# This script is used make a full roundtrip test to SimpleSAMLphp based SSO
# Exit statuses indicate problem and are suitable for usage in Nagios.

basename=$(basename $0)

muniTestSite=$1
muniLoginSite=$2
muniLogin=$3
muniPasswd=$4

cesnetTestSite=$5
cesnetLoginSite=$6
cesnetLogin=$7
cesnetPasswd=$8

warningTime=10
warningTime=$9

setMuniStatus()
{
    muniLoginStatus=$1
    muniStatusTxt=$2

    # Clean up
    rm -f ${cookieJar}

    # Calculate time difference
    endTime=$(date +%s%N)
    muniTotalTime=$(expr $endTime - $startTime)
    muniLoginTime=$(echo "scale=4;$muniTotalTime / 1000000000" | bc -l)
}

setCesnetStatus()
{
    cesnetLoginStatus=$1
    cesnetStatusTxt=$2

    # Clean up
    rm -f ${cookieJar}

    # Calculate time difference
    endTime=$(date +%s%N)
    cesnetTotalTime=$(expr $endTime - $startTime)
    cesnetLoginTime=$(echo "scale=4;$cesnetTotalTime / 1000000000" | bc -l)
}

authMuni()
{
    testSite=$1
    loginSite=$2
    login=$3
    password=$4

    cookieJar=$(mktemp /tmp/${basename}.XXXXXX) || exit 3
    startTime=$(date +%s%N)

    # REQUEST #1: fetch URL for authentication page
    html=$(curl -L -sS -c ${cookieJar} -w 'LAST_URL:%{url_effective}' --resolve ${proxyDomainName}':443:'${ip} ${testSite}) || (setMuniStatus 2 "Failed to fetch URL: $testSite" && return)

    # Parse HTML to get the URL where to POST login (written out by curl itself above)
    authURL=$(echo ${html} | sed -e 's/.*LAST_URL:\(.*\)$/\1/')
    authState=$(echo ${html} | sed -e 's/.*hidden[^>]*AuthState[^>]*value=[\"'\'']\([^\"'\'']*\)[\"'\''].*/\1/')

    # We should be redirected
    if [[ $authURL == "$testSite" ]]; then
        setMuniStatus 2 "No redirection to: $loginSite." && return
    fi

    # REQUEST #2: log in
    html=$(curl -L -s -c ${cookieJar} -b ${cookieJar} -w 'LAST_URL:%{url_effective}' \
    -d "j_username=$login" -d  "j_password=$password" --data-urlencode "AuthState=${authState}" --resolve ${proxyDomainName}':443:'${ip} ${authURL}) || (setMuniStatus 2 "Failed to fetch URL: $authURL" && return)
    lastURL=$(echo ${html} | sed -e 's/.*LAST_URL:\(.*\)$/\1/')

    # We should be successfully logged in
    if [[ $lastURL == "$authURL" ]]; then
        setMuniStatus 2 "Invalid credentials."
        return
    fi

    # We do not support JS, so parse HTML for SAML endpoint and response
    proxySamlEndpoint=$(echo ${html} | sed -e 's/.*form[^>]*action=[\"'\'']\([^\"'\'']*\)[\"'\''].*method[^>].*/\1/' | php -R 'echo html_entity_decode($argn);')
    proxySamlResponse=$(echo ${html} | sed -e 's/.*hidden[^>]*SAMLResponse[^>]*value=[\"'\'']\([^\"'\'']*\)[\"'\''].*/\1/')
    if [[ $proxySamlEndpoint =~ .*\<html\>.* || $proxySamlResponse =~ .*\<html\>.* ]]; then
        setMuniStatus 2 "Not redirected to PROXY post data"
        return
    fi

    # REQUEST #3: post the SAMLResponse to proxy
    html=$(curl -L -s -c "${cookieJar}" -b "${cookieJar}" -w 'LAST_URL:%{url_effective}' \
    --data-urlencode "SAMLResponse=${proxySamlResponse}" --resolve ${proxyDomainName}':443:'${ip} ${proxySamlEndpoint}) || (setMuniStatus 2 "Failed to fetch URL: $proxySamlEndpoint" && return)
    lastURL=$(echo ${html} | sed -e 's/.*LAST_URL:\(.*\)$/\1/')

    # We should be redirected to perform POST request to Shibboleth SP
	  if [[ $html == *errorreport.php* ]]; then
      errorMessage=$(echo ${html} | sed -e 's/.*<h1>.*<\/i>\s\(.*\)\s<\/h1>.*id="content">\s<p>\s\(.*\)<a.*moreInfo.*/\1 - \2/g')
      setMuniStatus 2 "Got error: ${errorMessage} "
      return
    fi

    # We do not support JS, so parse HTML for SAML endpoint and response
    spSamlEndpoint=$(echo ${html} | sed -e 's/.*form[^>]*action=[\"'\'']\([^\"'\'']*\)[\"'\''].*method[^>].*/\1/')
    spSamlResponse=$(echo ${html} | sed -e 's/.*hidden[^>]*SAMLResponse[^>]*value=[\"'\'']\([^\"'\'']*\)[\"'\''].*/\1/')
    spRelayState=$(echo ${html} | sed -e 's/.*hidden[^>]*RelayState[^>]*value=[\"'\'']\([^\"'\'']*\)[\"'\''].*/\1/')

    if [[ $spSamlEndpoint =~ .*\<html\>.* || $spSamlResponse =~ .*\<html\>.* || $spRelayState =~ .*\<html\>.* ]]; then
        setMuniStatus 2 "Not redirected to SP post data"
        return
    fi

    # REQUEST #4: post the SAMLResponse to SP
    html=$(curl -L -s -c "${cookieJar}" -b "${cookieJar}" -w 'LAST_URL:%{url_effective}' \
    --data-urlencode "SAMLResponse=${spSamlResponse}" --data-urlencode "RelayState=${spRelayState}" --resolve ${proxyDomainName}':443:'${ip} ${spSamlEndpoint}) || (setMuniStatus 2 "Failed to fetch URL: $spSamlEndpoint" && return)
    lastURL=$(echo ${html} | sed -e 's/.*LAST_URL:\(.*\)$/\1/')

    # OIDC adds some params to the "testSite" URL so we need to compare like this
    match=$(echo $lastURL | sed -e "s/\(https.*aai-playground.*code=.*state=.*\)$/OK/")
    if [[ $match == 'OK' ]]; then
        result=$(echo ${html} | sed -e 's/.*<body>\sResult-\(.*\)\s<\/body.*$/\1/')
        if [[ $result == "OK" ]]; then
            setMuniStatus 0 "Successful login"
        else
            setMuniStatus 2 "Bad result: $result."
        fi
    else
        setMuniStatus 2 "Not redirected back to: $testSite&code=...&state=...."
    fi
}

authCesnet()
{
    testSite=$1
    loginSite=$2
    login=$3
    password=$4

    cookieJar=$(mktemp /tmp/${basename}.XXXXXX) || exit 3
    startTime=$(date +%s%N)

    # REQUEST #1: fetch URL for authentication page
    html=$(curl -L -s -c "${cookieJar}" -w 'LAST_URL:%{url_effective}' --resolve ${proxyDomainName}':443:'${ip} "${testSite}") || (setCesnetStatus 2 "Failed to fetch URL: $testSite" && return)

    # Parse HTML to get the URL where to POST login (written out by curl itself above)
    authURL=$(echo ${html} | sed -e 's/.*LAST_URL:\(.*\)$/\1/')

    # We should be redirected
    if [[ $authURL == "$testSite" ]]; then
        setCesnetStatus 2 "No redirection to: $loginSite."
        return
    fi

    # REQUEST #2: log in
    html=$(curl -L -s -c "${cookieJar}" -b "${cookieJar}" -w 'LAST_URL:%{url_effective}' -d "j_username=$login" -d  "j_password=$password" -d "_eventId_proceed=" --data-urlencode --resolve ${proxyDomainName}':443:'${ip} "${authURL}") || (setCesnetStatus 2 "Failed to fetch URL: $authURL" && return)
    lastURL=$(echo ${html} | sed -e 's/.*LAST_URL:\(.*\)$/\1/')

    # We do not support JS, so parse HTML for SAML endpoint and response
    proxySamlEndpoint=$(echo ${html} | sed -e 's/.*form[^>]*action=[\"'\'']\([^\"'\'']*\)[\"'\''].*method[^>].*/\1/' | php -R 'echo html_entity_decode($argn);')
    proxySamlResponse=$(echo ${html} | sed -e 's/.*hidden[^>]*SAMLResponse[^>]*value=[\"'\'']\([^\"'\'']*\)[\"'\''].*/\1/')

    if [[ $authURL != "$lastURL" ]]; then
        setCesnetStatus 2 "Invalid credentials."
        return
    elif [[ $proxySamlEndpoint =~ .*\<html\>.* || $proxySamlResponse =~ .*\<html\>.* ]]; then
        setCesnetStatus 2 "Not redirected to PROXY post data"
        return
    fi

    # REQUEST #3: post the SAMLResponse to proxy
    html=$(curl -L -s -c "${cookieJar}" -b "${cookieJar}" -w 'LAST_URL:%{url_effective}' \
    --data-urlencode "SAMLResponse=${proxySamlResponse}" --resolve "${proxyDomainName}"':443:'${ip} "${proxySamlEndpoint}") || (setCesnetStatus 2 "Failed to fetch URL: $proxySamlEndpoint" && return)

    if [[ $html == *errorreport.php* ]]; then
        errorMessage=$(echo "${html}" | sed -e 's/.*<h1>.*<\/i>\s\(.*\)\s<\/h1>.*id="content">\s<p>\s\(.*\)<a.*moreInfo.*/\1 - \2/g')
        setCesnetStatus 2 "Got error: ${errorMessage} "
        return
    fi

    # We do not support JS, so parse HTML for SAML endpoint and response
    spSamlEndpoint=$(echo ${html} | sed -e 's/.*form[^>]*action=[\"'\'']\([^\"'\'']*\)[\"'\''].*method[^>].*/\1/')
    spSamlResponse=$(echo ${html} | sed -e 's/.*hidden[^>]*SAMLResponse[^>]*value=[\"'\'']\([^\"'\'']*\)[\"'\''].*/\1/')
    spRelayState=$(echo ${html} | sed -e 's/.*hidden[^>]*RelayState[^>]*value=[\"'\'']\([^\"'\'']*\)[\"'\''].*/\1/')

    if [[ $spSamlEndpoint =~ .*\<html\>.* || $spSamlResponse =~ .*\<html\>.* || $spRelayState =~ .*\<html\>.* ]]; then
        setCesnetStatus 2 "Not redirected to SP post data"
        return
    fi

    # REQUEST #4: post the SAMLResponse to SP
    html=$(curl -L -s -c ${cookieJar} -b ${cookieJar} -w 'LAST_URL:%{url_effective}' \
    --data-urlencode "SAMLResponse=${spSamlResponse}" --data-urlencode "RelayState=${spRelayState}" --resolve ${proxyDomainName}':443:'${ip} ${spSamlEndpoint}) || (setCesnetStatus 2 "Failed to fetch URL: $spSamlEndpoint" && return)
    lastURL=$(echo ${html} | sed -e 's/.*LAST_URL:\(.*\)$/\1/')    match=$(echo $lastURL | sed -e "s/\(https.*aai-playground.*code=.*state=.*\)$/OK/")
    if [[ $match == 'OK' ]]; then
        result=$(echo ${html} | sed -e 's/.*<body>\sResult-\(.*\)\s<\/body.*$/\1/')
        if [[ $result == "OK" ]]; then
            setCesnetStatus 0 "Successful login"
        else
            setCesnetStatus 2 "Bad result: $result."
        fi
    else
        setCesnetStatus 2 "Not redirected back to: $testSite&code=...&state=...."
    fi
}

authMuni ${muniTestSite} ${muniLoginSite} ${muniLogin} ${muniPasswd}
authCesnet ${cesnetTestSite} ${cesnetLoginSite} ${cesnetLogin} ${cesnetPasswd}

if [[ $muniLoginStatus -eq 0 && $cesnetLoginStatus -eq 0 ]]; then
    if [[ $muniTotalTime -gt $(( warningTime * 1000000000 )) || $cesnetTotalTime -gt $(( warningTime * 1000000000 )) ]];then
        status=1
        statusTxt="Successful login, but was too long(More than ${warningTime}s)!"
    else
        status=0
        statusTxt="Successful login!"
    fi
else
    if [[ $muniLoginStatus -eq 2 && $cesnetLoginStatus -eq 0 ]] || [[ $muniLoginStatus -eq 0 && $cesnetLoginStatus -eq 2 ]]; then
        status=1
        statusTxt="Only one of logins was successful!"
    else
        status=2
        statusTxt="Unsuccessful login!"
    fi
fi

echo "$status - $statusTxt [MUNI status - $muniStatusTxt(${muniLoginTime}s); CESNET status - $cesnetStatusTxt(${cesnetLoginTime}s)]"
exit $status
