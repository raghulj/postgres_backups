# Docker PostgreSQL Backup

This Docker container facilitates the automated backup of PostgreSQL databases to object storage using a cron scheduler. Designed for flexibility, it is compatible with Docker Swarm or Compose environments, catering to a variety of deployment needs. Configuration is straightforward: simply set your environment variables through an `.env` file or directly in your environment.

A nod to the open-source community: the inception of this project was inspired by another, whose name escapes me. My gratitude for the open-source ethos that made this possible.

## Key Features and Assumptions

- **Database Compatibility**: Primarily designed for PostgreSQL database servers.
- **Notification Service**: Utilizes Mailgun for sending email alerts in case of backup failures.
- **Scheduling**: Employs a cron scheduler for periodic backups. Additionally, backups can be triggered manually via the `backup.sh` script within the running container.
- **Storage Configuration**: Default environment variable prefix is `AWS_` for object storage, but it is adaptable to other storage solutions.
- **Health Checks**: Implements healthcheck endpoints for signaling the completion of backups.

## Environment variables used

```sh
AWS_ACCESS_KEY_ID=access_id
AWS_SECRET_ACCESS_KEY=secret_access_key
AWS_ENDPOINT_URL=endpointurl
AWS_BUCKET_NAME=bucket_name_to_store
AWS_REGION=region_id
AWS_KEEP_FOR_DAYS=7
BACKUP_PATH=folder_to_store_in_bucket
BACKUP_CRON_SCHEDULE='1 14 * * *'
PGHOST=postgres_host_name
PGDATABASE=dbname
PGUSER=dbuser
PGPASSWORD=secretdbpassword
PGPORT=5432
MAIL_MAILGUN_KEY=mailgun_secret_key_for_sending_email
MAIL_MAILGUN_URL=mailgun_domain_endpoint_url_to_send_emails_from
MAIL_MAILGUN_FROM_ADDRESS="Admin <admin@example.com>"
MAIL_FAILURE_NOTIFICATION_EMAIL=myaddress@email.com
MAIL_SUBJECT='backup failed'
MAIL_BODY='Oops! Backup failed. Check it! Hurry!'
DB_COMPLETE_PING_URL=https://healthchecksurl

```

