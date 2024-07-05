FROM python:3.12.4-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    lbzip2 \
    bzip2 \
    gnupg2 \
    curl \
    cron \
    && rm -rf /var/lib/apt/lists/*


RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update -y && \
    apt-get install -y postgresql-client-14

RUN pip install boto3

# Create workdir
RUN mkdir /backup
WORKDIR /backup


# Copy scripts
COPY run_cron.sh /backup/run_cron.sh
RUN chmod 0700 /backup/run_cron.sh
COPY backup.sh /backup/backup.sh
RUN chmod 0700 /backup/backup.sh
COPY s3upload.py /backup/s3upload.py
RUN chmod 0700 /backup/s3upload.py
COPY notify.sh /backup/notify.sh
RUN chmod 0700 /backup/notify.sh


# Define default CRON_SCHEDULE to 1 your
ENV BACKUP_CRON_SCHEDULE='0 * * * *'
ENV BACKUP_PRIORITY="ionice -c 3 nice -n 10"

# Prepare cron
RUN touch /var/log/cron.log
ADD crontab /etc/cron.d/backup-cron
RUN chmod 0644 /etc/cron.d/backup-cron

# Run the command on container startup
ENTRYPOINT /backup/run_cron.sh

# For testing
# ENTRYPOINT sh /backup/backup.sh
