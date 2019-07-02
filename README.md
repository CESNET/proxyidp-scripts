# proxyidp-nagios-scripts

## List of Local scripts
Local scripts are located in /usr/lib/check_mk/local/ 

###  php_syntax_check.sh
* Attributes to be filled: 
<pre>
# List of paths to check separated by space
paths=""
</pre>

###  git_pull_check.sh
* Attributes to be filled: 
<pre>
# The root directory to check
dir=""
</pre>

### services_running_check.sh
* Attributes to be filled: 
<pre>
# List of service names separated by space
services=""
</pre>

### proxy_idp_auth_test.sh
This script checks the login to SP via the host, from which is the script runs

* Requirements:
    * library *bc* 
        <pre>
        apt-get install bc
        </pre>
* Attributes to be filled:
<pre>
# The url of tested SP
# For example: https://aai-playground.ics.muni.cz/simplesaml/nagios_check.php?proxy_idp=cesnet
testSite=""

# The url of login form of used IdP
# For example: https://idp2.ics.muni.cz/idp/Authn/UserPassword
loginSite=""

# Fill in login
login=""

# Fill in password as string
password=""

# Fill in the instance name
# Instance name must not contain a space
instanceName=""

# Fill in the global domain name of ProxyIdP
# For example: login.cesnet.cz
proxyDomainName="login.elixir-czech.org"
</pre>

## List of plugins
Plugins are located in /usr/lib/check_mk/plugins/ 

## Nagios active scripts
Active scripts are located in Nagios machine

### proxy_idp_auth_test_active.sh
This script checks the login via active ProxyIdP machine

* How to run this script:
    * Params:
        * 1 - The url of tested SP 
        * 2 - The url of login form of used IdP
        * 3 - Login
        * 4 - Password
        * 5 - Roundtrip time (in seconds)
            - Default value = 10
    * Example:
        <pre>
        ./proxy_idp_auth_test_active.sh "https://aai-playground.ics.muni.cz/simplesaml/nagios_check.php?proxy_idp=cesnet" "https://idp2.ics.muni.cz/idp/Authn/UserPassword" "login" "passwd" 10
        </pre>

### mariadb_replication_check.sh
This script checks the database replication

* How to run this script:
    * Params:
        * 1 - Login used for connection to the database
        * 2 - Password used for connection to the database (the password has to be in quotes)
        * 3 - List of addresses separated by space (the list has to be in quotes)
    * Example:
        <pre>
        ./mariadb_replication_check.sh "USER" "PASSWORD" "Address1 Address2 Address3"
        </pre>
        