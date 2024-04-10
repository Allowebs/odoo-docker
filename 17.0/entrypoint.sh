#!/bin/bash

set -e

# If a PASSWORD_FILE is specified and exists, use it to set the PASSWORD variable
if [ -v PASSWORD_FILE ]; then
    PASSWORD="$(< $PASSWORD_FILE)"
fi

# Set default values from .env variables or fallback to defaults
: ${HOST:=${ODOO_DATABASE_HOST:='db'}}
: ${PORT:=${ODOO_DATABASE_PORT:=5432}}
: ${USER:=${ODOO_DATABASE_USER:='odoo'}}
: ${PASSWORD:=${ODOO_DATABASE_PASSWORD:='odoo'}}
: ${EMAIL_FROM:=${ODOO_EMAIL_FROM:='odoo@example.com'}}
: ${SMTP_HOST:=${ODOO_SMTP_HOST:='smtp.example.com'}}
: ${SMTP_PORT:=${ODOO_SMTP_PORT_NUMBER:=587}}
: ${SMTP_USER:=${ODOO_SMTP_USER:='user@example.com'}}
: ${SMTP_PASSWORD:=${ODOO_SMTP_PASSWORD:='password'}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then       
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" | cut -d "=" -f2 | sed 's/["\n\r]//g')
    fi
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}

# Check and set the database and SMTP configuration
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"
check_config "email_from" "$EMAIL_FROM"
check_config "smtp_host" "$SMTP_HOST"
check_config "smtp_port" "$SMTP_PORT"
check_config "smtp_user" "$SMTP_USER"
check_config "smtp_password" "$SMTP_PASSWORD"

case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec odoo "$@"
        else
            wait-for-psql.py "${DB_ARGS[@]}" --timeout=30
            exec odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        wait-for-psql.py "${DB_ARGS[@]}" --timeout=30
        exec odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec "$@"
esac

exit 1
