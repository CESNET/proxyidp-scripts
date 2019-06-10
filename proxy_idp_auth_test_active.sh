#!/bin/bash

# This script is used make a full roundtrip test to SimpleSAMLphp based SSO
# Exit statuses indicate problem and are suitable for usage in Nagios.

basename=$(basename $0)

# The url of tested SP
testSite=$1

# The url of login form of used IdP
loginSite=$2

# Login
login=$3

# Password
password=$4


# End function
end()
{
status=$1
statustxt=$2

# Clean up
rm -f ${cookieJar}

echo "$statustxt"
exit $status
}

hasErrorReportForm()
{
if [[ $@ == *errorreport.php* ]]; then
    errorMessage=$(echo ${html} | sed -e 's/.*<h1>.*<\/i>\s\(.*\)\s<\/a><\/h1>.*id="content">\s<p>\s\(.*\)<a.*moreInfo.*/\1 - \2/')
    end 2 "Get error: ${errorMessage} "
fi

}

cookieJar=$(mktemp /tmp/${basename}.XXXXXX) || exit 3

# REQUEST #1: fetch URL for authentication page
html=$(curl -L -sS -c ${cookieJar} -w 'LAST_URL:%{url_effective}' ${testSite}) || end 2 "CRIT - Failed to fetch URL: $testSite"

# Parse HTML to get the URL where to POST login (written out by curl itself above)
authURL=$(echo ${html} | sed -e 's/.*LAST_URL:\(.*\)$/\1/')
authState=$(echo ${html} | sed -e 's/.*hidden[^>]*AuthState[^>]*value=[\"'\'']\([^\"'\'']*\)[\"'\''].*/\1/')

# We should be redirected
if [[ $authURL == $testSite ]]; then
    end 2 "No redirection to: $loginSite."
fi

# REQUEST #2: log in
html=$(curl -L -sS -c ${cookieJar} -b ${cookieJar} -w 'LAST_URL:%{url_effective}' \
-d "j_username=$login" -d  "j_password=$password" --data-urlencode "AuthState=${authState}" ${authURL}) || end 2 "CRIT - Failed to fetch URL: $authURL"

lastURL=$(echo ${html} | sed -e 's/.*LAST_URL:\(.*\)$/\1/')

# We should be successfully logged in
if [[ $lastURL == $authURL ]]; then
    end 2 "Invalid credentials."
fi

# We do not support JS, so parse HTML for SAML endpoint and response
proxySamlEndpoint=$(echo ${html} | sed -e 's/.*form[^>]*action=[\"'\'']\([^\"'\'']*\)[\"'\''].*method[^>].*/\1/' | php -R 'echo html_entity_decode($argn);')
proxySamlResponse=$(echo ${html} | sed -e 's/.*hidden[^>]*SAMLResponse[^>]*value=[\"'\'']\([^\"'\'']*\)[\"'\''].*/\1/')

# REQUEST #3: post the SAMLResponse to proxy
html=$(curl -L -sS -c ${cookieJar} -b ${cookieJar} -w 'LAST_URL:%{url_effective}' \
  --data-urlencode "SAMLResponse=${proxySamlResponse}" ${proxySamlEndpoint}) || end 2 "CRIT - Failed to fetch URL: $proxySamlEndpoint"

hasErrorReportForm ${html}

# We do not support JS, so parse HTML for SAML endpoint and response
spSamlEndpoint=$(echo ${html} | sed -e 's/.*form[^>]*action=[\"'\'']\([^\"'\'']*\)[\"'\''].*method[^>].*/\1/')
spSamlResponse=$(echo ${html} | sed -e 's/.*hidden[^>]*SAMLResponse[^>]*value=[\"'\'']\([^\"'\'']*\)[\"'\''].*/\1/')

# REQUEST #4: post the SAMLResponse to SP
html=$(curl -L -sS -c ${cookieJar} -b ${cookieJar} -w 'LAST_URL:%{url_effective}' \
  --data-urlencode "SAMLResponse=${spSamlResponse}" ${spSamlEndpoint}) || end 2 "CRIT - Failed to fetch URL: $spSamlEndpoint"

lastURL=$(echo ${html} | sed -e 's/.*LAST_URL:\(.*\)$/\1/')

if [[ $lastURL ==  $testSite ]]; then
    result=$(echo ${html} | sed -e 's/.*<body>\s*Result-\(.*\)<.*$/\1/')
    if [[ $result == "OK " ]]; then
        end 0 "OK - Successful login."
    else
        end 2 "CRIT - Bad result: $result."
    fi

else
    end 2 "CRIT - Not redirected back to: $testSite."
fi
