# proxyidp-nagios-scripts

## List of Local scripts
Local scripts are located in /usr/lib/check_mk/local/ 

###  git_pull_check.sh
* Attributes to be filled: 
<pre>
# List of paths to check separated by space
paths=""
</pre>

### services_running_check.sh
* Attributes to be filled: 
<pre>
# List of service names separated by space
services=""
</pre>

### proxy_idp_auth_test.sh
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
</pre>

## List of plugins
Plugins are located in /usr/lib/check_mk/plugins/ 
