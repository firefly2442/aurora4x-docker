# aurora4x-docker

![GitHub Workflow Status (branch)](https://img.shields.io/github/actions/workflow/status/firefly2442/aurora4x-docker/ci.yml?branch=master)

A Docker container with [Aurora4x (C#)](http://aurora2.pentarch.org/) accessible via a web-browser.

## Prerequisites

* Install [Docker](https://www.docker.com/) or [Podman](https://podman.io/docs/installation#installing-on-linux)

## Install Prebuilt Image

```shell
docker pull ghcr.io/firefly2442/aurora4x-docker:latest
```

Or

```shell
podman pull ghcr.io/firefly2442/aurora4x-docker:latest
```

Images are hosted on [Github Container Registry](https://github.com/firefly2442/aurora4x-docker/pkgs/container/aurora4x-docker).

## Building From Scratch

```shell
docker build . -t ghcr.io/firefly2442/aurora4x-docker:latest
```

## Running

Use the most recent patch and find the `AuroraDB.db` file.  Place this in the sourcecode folder
or wherever you're wanting to start it up.  Change `<path to your local Aurora.db>` in the below command to the full path to
your `AuroraDB.db` file.  This will allow saving via Docker to persist on your local disk.

```shell
docker run -p 6080:3000 --name=aurora4x-docker -v /dev/shm:/dev/shm -v /<path to your local Aurora.db>/AuroraDB.db:/config/AuroraDB.db ghcr.io/firefly2442/aurora4x-docker
```

Or

```shell
podman run -p 6080:3000 -v /dev/shm:/dev/shm -v /<path to your local Aurora.db>/AuroraDB.db:/config/AuroraDB.db aurora4x-docker
```

Open [http://localhost:6080](http://localhost:6080) in your browser.

Double-click the `Aurora4x` icon on the desktop and then select execute.
If saving the game gives you permission issues, you may need to run the game from the command line with:
```shell
sudo /config/Aurora.sh
```

## Security

Depending on where you are running this and/or your network settings, this container
could be visible to the outside world.  Be careful that this not be used as
an attack vector onto your systems.

## Why Docker

Since the sourcecode to Aurora4x hasn't been released, we can't compile it for other
systems.  This allows people on Mac and Linux to play too.  There are some "hacky"
things that need to be done to the underlying libraries.  This prevents you
from needing to do these on your base Linux system and potentially hosing it.

## For Developers

* Copy `*.rar` files (full install, patches, etc.) into the cloned code to be copied
over to the container during the build.  This prevents constantly hitting the
pentarch.org servers and sucking up bandwidth.
* Get into the running container with `docker exec -it aurora4x-docker /bin/bash` or
just open up the `LXTerminal` app.
* Use `docker system prune` since the intermediate layers, particularly in the builder
are huge.
* Use `docker image ls` to see image sizes.
* Use the [Dive](https://github.com/wagoodman/dive) program to help debug
the image size, `dive ghcr.io/firefly2442/aurora4x-docker`.
* Use [Trivy](https://github.com/aquasecurity/trivy) for manual image vulnerability scanning,
e.g. `trivy image --ignore-unfixed ghcr.io/firefly2442/aurora4x-docker:latest`

## Support

* With the UI hacks needed as well as running things through Mono, please replicate
any bugs you find on a plain Windows install of Aurora4x.  This helps Steve keep
track of legitimate bugs and prevents any false-positives.
* `#aurora-linux` channel on Discord
* [Aurora forums](http://aurora2.pentarch.org/)

## Thanks To

* `twice2double` - for start of Dockerfile
* `cpw` - for font scaling hack
* Everyone else on `#aurora-linux` I forgot...
