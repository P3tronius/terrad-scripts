# Terra Validator node

This dockerfile generates an image with a sentry node ready to go.

### How to use
```
# checkout and cd to the directory
$ docker build --tag=terra_sentry_01:v1 .

# to run it, use 
$ docker run -d --name terrad-sentry-01 --mount source=terrad-data,target=/home/terra/.terrad/data terra_sentry_01:v1
```

Argument `--mount` is important and maps the directory `.terrad/data` to your host, so when destroying/recreating the container the data is persistent.

Be aware that a full node needs about 750Gb of space right now (06/2021) and keeps growing.

### Remaing steps

The node start from scratch, which is not recommended.
To get the latest snapshot from Chainlayer, get the latest archive from https://terra.quicksync.io/ (default version) on the host, and unzip it directly in the mounted volume mapped by docker.

For Windows: \\wsl$\docker-desktop-data\version-pack-data\community\docker\volumes\
For Linux:  `docker volume inspect terrad-data` will show you the mount point.
