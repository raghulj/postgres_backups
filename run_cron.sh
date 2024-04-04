#!/bin/bash

# change cron schedule
BACKUP_CRON_SCHEDULE="${BACKUP_CRON_SCHEDULE//\'}"
sed -i "s,CRON_SCHEDULE*,${BACKUP_CRON_SCHEDULE},g" /etc/cron.d/backup-cron

# Collect environment variables set by docker
env | egrep '^AWS|^PG|^BACKUP|^MAIL' | sort > /tmp/backup-cron
cat /etc/cron.d/backup-cron >> /tmp/backup-cron
mv /tmp/backup-cron /etc/cron.d/backup-cron

chmod 0644 /etc/cron.d/backup-cron

cron  && tail -f /var/log/cron.log
