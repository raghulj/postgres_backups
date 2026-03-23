FROM python:3.13-slim-bookworm

ARG PG_VERSION=16
LABEL pgversion=v${PG_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg2 \
    lbzip2 \
    bzip2 \
    curl \
    cron \
    && rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir boto3==1.42.73

RUN echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-${PG_VERSION} postgresql-common && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /backup

COPY run_cron.sh backup.sh s3upload.py notify.sh ./
RUN chmod 0700 run_cron.sh backup.sh s3upload.py notify.sh && \
    touch /var/log/cron.log

COPY crontab /etc/cron.d/backup-cron
RUN chmod 0644 /etc/cron.d/backup-cron

ENV BACKUP_CRON_SCHEDULE='0 * * * *' \
    BACKUP_PRIORITY="ionice -c 3 nice -n 10"

ENTRYPOINT ["/backup/run_cron.sh"]

# For testing
# ENTRYPOINT sh /backup/backup.sh
