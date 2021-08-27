# ProxyIdP scripts

All nagios scripts are located under `nagios` directory.

## List scripts

### separate_ssp_script.py
* Script for remove all logs from test accounts from SimpleSAMLlogs

* Params:
    * 1 - The file name
    
### backup_database.sh
* Do mysqldump into `/opt/mariadb_backup` and remove all dump file older than 7 days

### separate_oidc_logs.py
* Script for remove all logs from test accounts from OIDC logs

### metadata_expiration.py
* This script checks whether there are some metadata close to expiration date

* Params:
  * 1 - url to a page which prints a time when expires the metadata closest to expiration