#!/bin/bash

BACKUP_FOLDER="/opt/mariadb_backup"

# Ensure that backup folder exist
if [[ ! -d ${BACKUP_FOLDER} ]]; then
    mkdir ${BACKUP_FOLDER}
fi

BACKUP_FILE_NAME=${BACKUP_FOLDER}/backup_$(date -u +'%Y-%m-%d_%HH:%MM').sql

# Backup all databases
mysqldump --all-databases > ${BACKUP_FILE_NAME}

echo "Database was dumped into ${BACKUP_FILE_NAME}"

#Remove old backups > 7days
find ${BACKUP_FOLDER} -name "backup_*.sql" -type f -mtime +7 -delete
