#!/bin/bash

if ! curl -s --user "api:${MAIL_MAILGUN_KEY}" "${MAIL_MAILGUN_URL}" \
    -F "from=${MAIL_MAILGUN_FROM_ADDRESS}" \
    -F "to=${MAIL_FAILURE_NOTIFICATION_EMAIL}" \
    -F "subject=${MAIL_SUBJECT}" \
    -F "text=${MAIL_BODY}"; then
    echo "$(date) ERROR: Failed to send failure notification email" >&2
fi
