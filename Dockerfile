# Builder stage
FROM python:3.12.4-slim-bookworm AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-16 postgresql-common && \
    rm -rf /var/lib/apt/lists/*

# Final stage
FROM python:3.12.4-slim-bookworm

LABEL pgversion=v16

COPY --from=builder /usr/bin/pg_dump /usr/bin/
COPY --from=builder /usr/lib/postgresql /usr/lib/postgresql

RUN apt-get update && apt-get install -y --no-install-recommends \
    lbzip2 \
    bzip2 \
    curl \
    cron \
    && rm -rf /var/lib/apt/lists/* && \
    pip install --no-cache-dir boto3

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
