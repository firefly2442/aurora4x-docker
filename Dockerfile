# Use multi-stage builds, the first section compiles everything we need
# the second sets up the final image
# https://docs.docker.com/develop/develop-images/multistage-build/

# https://hub.docker.com/_/ubuntu/
FROM ubuntu:focal AS builder

# force tzdata to use UTC and don't prompt user
ENV DEBIAN_FRONTEND=noninteractive

# https://www.mono-project.com/download/preview/
RUN apt update && \
    apt install -y --no-install-recommends gnupg ca-certificates && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/ubuntu preview-focal main" | tee /etc/apt/sources.list.d/mono-official-preview.list && \
    apt update && \
    apt install -y --no-install-recommends git-core unzip p7zip-full p7zip-rar wget \
    # below are for compiling libgdiplus
    libgif-dev autoconf libtool automake build-essential gettext libglib2.0-dev libcairo2-dev libtiff-dev libexif-dev \
    # below are for compiling mono
    git autoconf libtool automake build-essential gettext cmake python3 curl libtool-bin && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# build libgdiplus
# https://github.com/mono/libgdiplus
RUN git clone --recursive -b main --single-branch --depth=1 --shallow-submodules https://github.com/mono/libgdiplus.git
WORKDIR ./libgdiplus/
RUN ./autogen.sh && \
    make -j 4

WORKDIR ../

# TODO: apply cpw scaling patch overtop Mono master, is there a way to get this working without having to download ALL of the Mono repo history?
# try this? : https://stackoverflow.com/a/21217326/854874
# --shallow-since=<date> OR --shallow-exclude=<commit>  ?
# https://github.com/cpw/mono
# RUN git clone --recursive -b master --single-branch --depth=1 --shallow-submodules https://github.com/mono/mono.git && \
#     git add remote cpw https://github.com/cpw/mono.git && \
#     git remote update && \
#     git cherry-pick d9ecab07bb6558a1c8da9a2d71a55ebd57c321c6

# https://stackoverflow.com/questions/12535637/updating-git-submodule-fails
RUN git config --global url."http://github".insteadOf git://github
RUN git clone --recursive -b aurorafixes --single-branch --depth=1 --shallow-submodules https://github.com/cpw/mono.git

WORKDIR ./mono/

# the build system calls python but only python3 is available
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN ./autogen.sh
RUN make -j 4

WORKDIR ../

# http://blog.wezeku.com/2016/10/09/using-system-data-sqlite-under-linux-and-mono/
COPY sqlite-netFx-source-1.0.118.0.zip /
RUN unzip sqlite-netFx-source-1.0.118.0.zip -d ./sqlite/

WORKDIR ./sqlite/Setup/

RUN chmod +x compile-interop-assembly-release.sh && \
    ./compile-interop-assembly-release.sh

RUN mkdir -p /aurora/

WORKDIR ../../aurora/

# copy any Aurora files you might already have over, prevents needing to download them again
COPY *.rar /aurora/
COPY *.zip /aurora/
# on Dockerhub, this will copy over the blank.{rar/zip} file which is just a dummy to make sure
# the build doesn't fail

# download Aurora4x C#
# -nc prevents the file from being re-downloaded if it was copied over
# https://stackoverflow.com/questions/4944295/skip-download-if-files-exist-in-wget
RUN wget -nc http://www.pentarch.org/steve/Aurora1130Full.rar
RUN wget -nc http://www.pentarch.org/steve/Aurora250.rar
RUN wget -nc http://www.pentarch.org/steve/Aurora251.rar

# extract Aurora4x from the .rars/.zips, -y option accepts overwrites of files from the patches
RUN 7z x Aurora1130Full.rar -y && \
    7z x Aurora250.rar -y && \
    7z x Aurora251.rar -y && \
    rm *.rar && rm *.zip

# for debugging purposes, so we can start the container and examine the build results
#CMD tail -f /dev/null

# ----------------------------------

# https://github.com/linuxserver/docker-webtop
FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# https://www.mono-project.com/download/preview/
RUN apt update && \
    apt install -y --no-install-recommends wget gnupg ca-certificates fonts-cantarell && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add - && \
    sudo apt update && \
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/ubuntu preview-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-preview.list && \
    sudo apt update && \
    sudo apt install -y --no-install-recommends mono-complete fonts-cantarell && \
    sudo apt upgrade -y && \
    sudo apt autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# copy over library files from previous stage
# helps find the files we're interested in by recursively searching the builder
# find . -name "System.Drawing.dll"
COPY --from=builder /mono/mcs/class/lib/build-linux/System.Drawing.dll /config/System.Drawing.dll
COPY --from=builder /mono/mcs/class/lib/net_4_x-linux/System.Windows.Forms.dll /config/System.Windows.Forms.dll
COPY --from=builder /libgdiplus/src/.libs/libgdiplus.so.0 /config/libgdiplus.so.0
COPY --from=builder /sqlite/bin/2013/Release/bin/SQLite.Interop.dll /config/SQLite.Interop.dll
COPY --from=builder /sqlite/bin/2013/Release/bin/libSQLite.Interop.so /config/libSQLite.Interop.so
# copy over the Aurora files
COPY --from=builder /aurora/ /config/

# setup executable launcher
RUN mkdir /config/Desktop && \
    echo "FONT_NAME=\"Cantarell\" FONT_SIZE=7.5 SCALEHACKX=1.0225 SCALEHACKY=1.01 LC_ALL=C MONO_IOMAP=all mono Aurora.exe" > /config/Aurora.sh && \
    chmod +x /config/Aurora.sh && \
    chown abc /config/Aurora.sh
COPY Aurora.desktop /config/Desktop/Aurora.desktop
