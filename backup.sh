#!/bin/bash
set -o errexit
set -o nounset

echo "`date` ~~~~~~~~~~~ STARTING BACKUP ~~~~~~~~~~~~"
rm -f /tmp/backup.sql.dump.bz2

FILENAME=/tmp/backup.sql.dump
echo "`date` Creating postgres dump"

[ -z "$PGDATABASE" ] && CMD=pg_dumpall || CMD="pg_dump -Fc ${PGDATABASE}"
$BACKUP_PRIORITY $CMD > $FILENAME

FILESIZE=$(stat -c%s "$FILENAME")
echo "`date` Size of $FILENAME = $FILESIZE bytes."

if [ $FILESIZE -gt 10 ]
then
    echo "`date` Compressing dump"
    $BACKUP_PRIORITY bzip2 $FILENAME

    echo "`date` Uploading to S3"
    python /backup/s3upload.py
    echo "`date` Done!"
    curl -m 10 --retry 5 $DB_COMPLETE_PING_URL
else
    echo "`date` Backup failed!"
    /backup/notify.sh
fi
