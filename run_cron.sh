#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Validate cron schedule contains only safe characters
BACKUP_CRON_SCHEDULE="${BACKUP_CRON_SCHEDULE//\'}"
if [[ ! "$BACKUP_CRON_SCHEDULE" =~ ^[0-9\ \*\/\,\-]+$ ]]; then
    echo "FATAL: BACKUP_CRON_SCHEDULE contains invalid characters: $BACKUP_CRON_SCHEDULE" >&2
    exit 1
fi

# Change cron schedule
sed -i "s,CRON_SCHEDULE,${BACKUP_CRON_SCHEDULE},g" /etc/cron.d/backup-cron

# Collect environment variables set by docker
env | egrep '^AWS|^PG|^BACKUP|^MAIL|^DB_' | sort > /tmp/backup-cron
cat /etc/cron.d/backup-cron >> /tmp/backup-cron
mv /tmp/backup-cron /etc/cron.d/backup-cron

chmod 0600 /etc/cron.d/backup-cron

cron && tail -f /var/log/cron.log
