![Docker Pulls](https://img.shields.io/docker/pulls/byh0ki/restic-mc)
![GitHub release (latest by date including pre-releases)](https://img.shields.io/github/v/release/Byh0ki/docker-restic-mc?include_prereleases)

This repo contain a Dockerfile used to generate a restic docker image.

# Usage

The entrypoint of this container provide a simple wrapper on restic. It allows
you to call restic without worrying about the differents things you would need
to setup to use restic like env vars.

```bash
# The path of the volume inside the container
VOLUME_PATH='/data'

# The path you want to mount on the container
DATA_PATH='path/of/your/data'

IMAGE_TAG='0.4'

docker run -h "${HOSTNAME}" \
    --name="restic_${BACKUP_NAME}" \
    --rm \
    -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
    -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
    -e RESTIC_PASSWORD="${RESTIC_PASSWORD}" \
    -e RESTIC_REPO="${RESTIC_REPO}" \
    -e VOLUME_PATH="${VOLUME_PATH}" \
    -v "$DATA_PATH":"$VOLUME_PATH" \
    byh0ki/restic-mc:"${IMAGE_TAG}" <restic cmd>
```

To get a list of the supported env vars:
```bash
docker run --rm byh0ki/restic-mc:"${IMAGE_TAG}" -h
```

## Usage with sudo
By default, `sudo` doesn't forward the parent env to the sudoed command, so if
you set some vars in your shell before using sudo, none of them will be passed
to the container. In order to share them, your can use `sudo -E`

## Notes
- The container host must be set manually because restic use it to sort and work
on the different snapshots. For exemple the `prune` command will apply the policy
for each host individually.
