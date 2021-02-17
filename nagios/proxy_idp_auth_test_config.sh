# The urls of tested SP
# For example: https://aai-playground.ics.muni.cz/simplesaml/nagios_check.php?proxy_idp=cesnet&authentication=muni
AAI_SAML_TEST_SITE=""
AAI_OIDC_TEST_SITE=""
MUNI_SAML_TEST_SITE=""
MUNI_OIDC_TEST_SITE=""
CESNET_SAML_TEST_SITE=""
CESNET_OIDC_TEST_SITE=""

# The url of logins form of used IdP
# For example: https://idp2.ics.muni.cz/idp/Authn/UserPassword
AAI_LOGIN_SITE=""
MUNI_LOGIN_SITE=""
CESNET_LOGIN_SITE=""

# Fill in logins
AAI_LOGIN=""
MUNI_LOGIN=""
CESNET_LOGIN=""

# Fill in passwords as string
AAI_PASSWORD=""
MUNI_PASSWORD=""
CESNET_PASSWORD=""

# Fill in the instance name
# Instance name must not contain a space
INSTANCE_NAME=""

# Fill in the global domain name of ProxyIdP
# For example: login.cesnet.cz
PROXY_DOMAIN_NAME=""

# How long is normal for total roundtrip (seconds)
SAML_WARNING_TIME=10
OIDC_WARNING_TIME=15

# Timeout time
TIMEOUT_TIME=40

# Cache time
CACHE_TIME=60
