This repo contain a Dockerfile used to generate a docker image with restic and
minio client.

# Usage

The entrypoint of this container provide a simple wrapper on restic. It allows
you to call restic without worrying about the differents things you would need
to setup to use restic and minio like env vars.

In addition to restic commands, it also provides a command named `my_backup`.
This command is made to make a backup without problems, it:
- make a minio/s3 bucket (MINIO_BUCKET_NAME)
- check if the bucket contain a restic repository
- create one if needed
- backup
- prune the old snapshot according to BACKUP_FORGET_POLICY

```bash
# The path of the volume inside the container
VOLUME_PATH='/data'

# The path you want to mount on the container
DATA_PATH='path/of/your/data'

docker run -h "${HOSTNAME}" \
    --name="restic_${SERVICE_NAME}" \
    --rm \
    -e MINIO_ACCESS_KEY="${MINIO_ACCESS_KEY}" \
    -e MINIO_SECRET_KEY"${MINIO_SECRET_KEY}" \
    -e MINIO_HOST"${MINIO_HOST}" \
    -e MINIO_BUCKET_NAME="${BUCKET_NAME}" \
    -e RESTIC_PASSWORD"${RESTIC_PASSWORD}" \
    -e VOLUME_PATH="${VOLUME_PATH}" \
    -v "$DATA_PATH":"$VOLUME_PATH" \
    byh0ki/restic-mc:<tag> <rectic cmd>
```

To get a list of the supported env vars:
```bash
docker run --rm byh0ki/restic-mc:<tag> -h
```

## Usage with sudo
`sudo` doesn't forward the parent env to the sudoed command by default, so if
you set some vars in your shell before using sudo, none of them will be passed
to the container. In order to share them, your can use `sudo -E`

## Notes
- The container host must be set manually because restic use it to sort and work
on the different snapshots.
