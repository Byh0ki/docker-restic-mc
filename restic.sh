#!/usr/bin/env bash

set -e

usage()
{
    echo -e "$(basename "$0") [-h|--help] my_backup|<restic cmd>"
    echo -e "               [-h|--help] display this help message"
    echo -e "List of ENV vars used by this script (default):"
    echo
    echo -e "MINIO_CONNECTION_SCHEME    (https)"
    echo -e "MINIO_ACCESS_KEY"
    echo -e "MINIO_SECRET_KEY"
    echo -e "MINIO_HOST"
    echo -e "MINIO_HOST_PORT            (443)"
    echo -e "MINIO_BUCKET_NAME"
    echo -e "RESTIC_PASSWORD"
    echo -e "VOLUME_PATH                (/data)"
    echo -e "BACKUP_FORGET_POLICY       (--keep-daily 7 --keep-weekly 1 --keep-monthly 12)"
    echo
    echo -e "A restic cmd will call restic with the given arguments using the \
env vars to connect to the restic repository. NB: env vars like \
'BACKUP_FORGET_POLICY' are not taken in consideration while using restic \
commands."
    exit "${1:-1}"
}

check_env()
{
    env_var="MINIO_BUCKET_NAME MINIO_ACCESS_KEY MINIO_SECRET_KEY MINIO_HOST RESTIC_PASSWORD"
    local cur=""
    for var in $env_var; do
        eval cur=\$"$var"
        [[ -n "${cur}" ]] || (echo "'${var}' must not be empty." && usage)
    done
}

my_backup()
{
    # $@ : files and directories to backup relative to $VOLUME_PATH or options
    # for the backup
    mc mb -p "${MINIO_ALIAS}/${MINIO_BUCKET_NAME}"

    if ! restic_wrapper snapshots 1>/dev/null 2>&1; then
        echo "Restic repo is not initialized, initialize..."
        restic_wrapper init
    fi

    # Change dir to $VOLUME_PATH, it ensure that the snapshot will not have
    # something like /data at its root
    cd "$VOLUME_PATH"

    # Actual backup
    restic_wrapper backup "$@"

    # Deleting backups that do no comply with the policy
    # shellcheck disable=SC2086
    restic_wrapper forget ${BACKUP_FORGET_POLICY} --prune
}

restic_wrapper()
{
    restic -r "${RESTIC_REPO}" --no-cache "$@"
}

# Minio vars
MINIO_CONNECTION_SCHEME="${MINIO_CONNECTION_SCHEME:-https}"

# Backup vars
BACKUP_FORGET_POLICY="${BACKUP_FORGET_POLICY:---keep-daily 7 --keep-weekly 1 --keep-monthly 12}"

# Misc vars
VOLUME_PATH="${VOLUME_PATH:-/data}"
MINIO_ALIAS='minio_backup'

# Script
if [ "$#" -lt 1 ]; then
    usage 2
fi

# We check for the -h flag before the rest of the options
case "${1}" in
    -h|--help)
        usage 0
        ;;
esac

# Check if the env is valid
check_env

# Minio vars
export MC_HOST_${MINIO_ALIAS}="${MINIO_CONNECTION_SCHEME}://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_HOST}:${MINIO_HOST_PORT}"
export MINIO_ENDPOINT="s3:${MINIO_CONNECTION_SCHEME}://${MINIO_HOST}:${MINIO_HOST_PORT}"

# Restic vars
export RESTIC_REPO="${MINIO_ENDPOINT}/${MINIO_BUCKET_NAME}"
export AWS_ACCESS_KEY_ID=${MINIO_ACCESS_KEY}
export AWS_SECRET_ACCESS_KEY=${MINIO_SECRET_KEY}

case "$1" in
    "my_backup")
        shift # To remove `my_backup` from the args
        my_backup "$@"
        ;;
    *)
        restic_wrapper "$@"
        ;;
esac
