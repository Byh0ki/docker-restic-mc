#!/bin/bash

set -e

usage()
{
    echo -e "$(basename "$0") backup|check|ls|restore|snapshots|stats"
    echo -e "List of ENV vars used by this script (default):"
    echo
    echo -e "DATE_FORMAT                (%D-%T)"
    echo -e "MINIO_CONNECTION_SCHEME    (https)"
    echo -e "MINIO_ACCESS_KEY"
    echo -e "MINIO_SECRET_KEY"
    echo -e "MINIO_HOST"
    echo -e "MINIO_HOST_PORT            (443)"
    echo -e "MINIO_BUCKET_NAME"
    echo -e "RESTIC_PASSWORD"
    echo -e "BACKUP_PATH                (/data/backup)"
    echo -e "BACKUP_FORGET_POLICY       (--keep-daily 7 --keep-weekly 1 --keep-monthly 12)"
    echo -e "FILES_TO_BACKUP            (.) => everything in \$BACKUP_PATH"
    echo -e "RESTORE_PATH               (/data/restore)"
    echo -e "RESTORE_EXTRA_ARGS"
    echo -e "SNAPSHOT_ID                (latest)"
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

backup()
{
    echo "Starting backup at $(date +"${DATE_FORMAT}")"

    mc mb -p "${BACKUP_ALIAS}/${MINIO_BUCKET_NAME}"

    if ! restic -r "${RESTIC_REPO}" --no-cache snapshots 1>/dev/null 2>&1; then
        echo "Restic repo is not initialized, initialize..."
        restic -r "${RESTIC_REPO}" --no-cache init
    fi

    # Change dir to $BACKUP_PATH, it ensure that the snapshot will not have
    # something like /data/backup at its root
    cd "$BACKUP_PATH"

    # Actual backup
    # shellcheck disable=SC2086
    restic -r "${RESTIC_REPO}" --no-cache backup ${FILES_TO_BACKUP}

    # Deleting backups that do no comply with the policy
    # shellcheck disable=SC2086
    restic -r "${RESTIC_REPO}" --no-cache forget ${BACKUP_FORGET_POLICY} --prune

    echo "Backup completed at $(date +"${DATE_FORMAT}")"
}

check()
{
    restic -r "${RESTIC_REPO}" --no-cache check
}

ls_repo()
{
    restic -r "${RESTIC_REPO}" --no-cache ls "${SNAPSHOT_ID}"
}

restore()
{
    echo "Starting restore at $(date +"${DATE_FORMAT}")"

    # shellcheck disable=SC2086
    restic -r "${RESTIC_REPO}" --no-cache restore "${SNAPSHOT_ID}" --target "${RESTORE_PATH}" $RESTORE_EXTRA_ARGS

    echo "Restore completed at $(date +"${DATE_FORMAT}")"
}

snapshots()
{
    restic -r "${RESTIC_REPO}" --no-cache snapshots
}

stats()
{
    restic -r "${RESTIC_REPO}" --no-cache stats "${SNAPSHOT_ID}"
}

# Minio vars
MINIO_CONNECTION_SCHEME="${MINIO_CONNECTION_SCHEME:-https}"

# Backup vars
BACKUP_PATH="${BACKUP_PATH:-/data/backup}"
BACKUP_FORGET_POLICY="${BACKUP_FORGET_POLICY:---keep-daily 7 --keep-weekly 1 --keep-monthly 12}"

# Restore vars
RESTORE_PATH="${RESTORE_PATH:-/data/restore}"
SNAPSHOT_ID="${SNAPSHOT_ID:-latest}"
RESTORE_EXTRA_ARGS="${RESTORE_EXTRA_ARGS}"

# Misc vars
BACKUP_ALIAS='minio_backup'
DATE_FORMAT="${DATE_FORMAT:-%D-%T}"

# Check if the env is valid
check_env

# Minio vars
export MC_HOST_${BACKUP_ALIAS}="${MINIO_CONNECTION_SCHEME}://${MINIO_ACCESS_KEY}:${MINIO_SECRET_KEY}@${MINIO_HOST}:${MINIO_HOST_PORT}"
export MINIO_ENDPOINT="s3:${MINIO_CONNECTION_SCHEME}://${MINIO_HOST}:${MINIO_HOST_PORT}"

# Restic vars
export RESTIC_REPO="${MINIO_ENDPOINT}/${MINIO_BUCKET_NAME}"
export AWS_ACCESS_KEY_ID=${MINIO_ACCESS_KEY}
export AWS_SECRET_ACCESS_KEY=${MINIO_SECRET_KEY}

if [ "$#" -ne 1 ]; then
    usage 2
fi

case "$1" in
    "backup")
        backup
        ;;
    "check")
        check
        ;;
    "ls")
        ls_repo
        ;;
    "restore")
        restore
        ;;
    "snapshots")
        snapshots
        ;;
    "stats")
        stats
        ;;
    *)
        usage 2
esac
