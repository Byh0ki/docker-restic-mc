#!/usr/bin/env bash

set -e

usage()
{
    echo -e "$(basename "$0") [-h|--help] <restic cmd>"
    echo -e "               [-h|--help] display this help message"
    echo -e "List of ENV vars used by this script (default):"
    echo
    echo -e "RESTIC_REPO"
    echo -e "RESTIC_PASSWORD"
    echo -e "VOLUME_PATH                (/data)"
    echo
    echo -e "A restic cmd will call restic with the given arguments using the \
env vars to connect to the restic repository, so you must provide a way to \
access your repo in the env. For exemple, for a S3 repository, you must \
provide:
 - AWS_ACCESS_KEY_ID
 - AWS_SECRET_ACCESS_KEY"
    exit "${1:-1}"
}

check_env()
{
    env_var="RESTIC_REPO RESTIC_PASSWORD"
    local cur=""
    for var in $env_var; do
        eval cur=\$"$var"
        [[ -n "${cur}" ]] || (echo "'${var}' must not be empty." && usage)
    done
}

restic_wrapper()
{
    restic -r "${RESTIC_REPO}" --no-cache "$@"
}

# Misc vars
VOLUME_PATH="${VOLUME_PATH:-/data}"

# Script
if [ "$#" -lt 1 ]; then
    usage 2
fi

# Check if the env is valid
check_env

case "${1}" in
    -h|--help)
        usage 0
        ;;
    *)
        restic_wrapper "$@"
        ;;
esac
