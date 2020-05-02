# aurora4x-docker

A Docker container with [Aurora4x (C#)](http://aurora2.pentarch.org/) accessible via a web-browser.

## Prerequisites

* Install [Docker](https://www.docker.com/)

## Install Prebuilt Docker Image

TODO: hub.docker.com...

## Building From Scratch

TODO: mount `AuroraDB.db` file so it saves it across restarts

```shell
docker build . -t firefly2442/aurora4x-docker
docker run -p 6080:80 --name=aurora4x-docker -v /dev/shm:/dev/shm firefly2442/aurora4x-docker
```

## Running

Open `http://localhost:6080`

Double-click the `Aurora` icon on the desktop.

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
