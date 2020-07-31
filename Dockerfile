# Use multi-stage builds, the first section compiles everything we need
# the second sets up the final iamge
# https://docs.docker.com/develop/develop-images/multistage-build/

# https://hub.docker.com/_/ubuntu/
FROM ubuntu:bionic AS builder

# https://www.mono-project.com/download/preview/
RUN apt update && \
    apt install -y --no-install-recommends gnupg ca-certificates && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/ubuntu preview-bionic main" | tee /etc/apt/sources.list.d/mono-official-preview.list && \
    apt update && \
    apt install -y --no-install-recommends git-core unzip \
    # below are for compiling libgdiplus
    libgif-dev autoconf libtool automake build-essential gettext libglib2.0-dev libcairo2-dev libtiff-dev libexif-dev \
    # below are for compiling mono
    git autoconf libtool automake build-essential gettext cmake python3 curl libtool-bin && \
    apt autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# build libgdiplus
# https://github.com/mono/libgdiplus
RUN git clone --recursive -b master --single-branch --depth=1 --shallow-submodules https://github.com/mono/libgdiplus.git
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

RUN git clone --recursive -b aurorafixes --single-branch --depth=1 --shallow-submodules https://github.com/cpw/mono.git

WORKDIR ./mono/

# the build system calls python but only python3 is available
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN ./autogen.sh
RUN make -j 4

WORKDIR ../

# http://blog.wezeku.com/2016/10/09/using-system-data-sqlite-under-linux-and-mono/
COPY sqlite-netFx-source-1.0.112.0.zip /
RUN unzip sqlite-netFx-source-1.0.112.0.zip -d ./sqlite/

WORKDIR ./sqlite/Setup/

RUN chmod +x compile-interop-assembly-release.sh && \
    ./compile-interop-assembly-release.sh

WORKDIR ../../

# for debugging purposes, so we can start the container and examine the build results
#CMD tail -f /dev/null

# ----------------------------------

# https://hub.docker.com/r/dorowu/ubuntu-desktop-lxde-vnc/
FROM dorowu/ubuntu-desktop-lxde-vnc:latest

# Everything is setup and run as root.
# The 'working directory' for Docker commands and root is /root/

# https://www.mono-project.com/download/preview/
RUN sudo apt update && \
    sudo apt install -y --no-install-recommends gnupg ca-certificates && \
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/ubuntu preview-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-preview.list && \
    sudo apt update && \
    sudo apt upgrade -y && \
    sudo apt install -y --no-install-recommends mono-complete wget fonts-cantarell p7zip-full p7zip-rar && \
    rm -rf /var/lib/apt/lists/*

# TODO: copy over library files from previous stage
# helps find the files we're interested in by recursively searching the builder
# find . -name "System.Drawing.dll"
COPY --from=builder /mono/mcs/class/lib/build-linux/System.Drawing.dll /root/System.Drawing.dll
COPY --from=builder /mono/mcs/class/lib/net_4_x-linux/System.Windows.Forms.dll /root/System.Windows.Forms.dll
COPY --from=builder /libgdiplus/src/.libs/libgdiplus.so.0 /root/libgdiplus.so.0
COPY --from=builder /sqlite/bin/2013/Release/bin/SQLite.Interop.dll /root/SQLite.Interop.dll
COPY --from=builder /sqlite/bin/2013/Release/bin/libSQLite.Interop.so /root/libSQLite.Interop.so

# copy any Aurora files you might already have over, prevents needing to download them again
COPY *.rar /root/

# download Aurora4x C#
# -nc prevents the file from being re-downloaded if it was copied over
# https://stackoverflow.com/questions/4944295/skip-download-if-files-exist-in-wget
RUN wget -nc http://www.pentarch.org/steve/Aurora151Full.rar
# patches to apply
RUN wget -nc http://www.pentarch.org/steve/Aurora1110.rar

# md5sum *.rar
# 19113d9b9aef38858b8ca03a423be747  Aurora151Full.rar
# 82b0264bcef8d233a2abef5f05ff0f8c  Aurora1110.rar

# extract Aurora4x from the .rars, -y option accepts overwrites of files from the patches
RUN 7z x Aurora151Full.rar && \
    7z x Aurora1110.rar -y && \
    rm *.rar

# TODO: what else can be removed to lighten the size?
# use wajig to find large packages that are left dangling that could be removed to save space
# $ apt update && apt install wajig
# $ wajig large
RUN sudo apt purge -y firefox google-chrome-stable wget p7zip-full p7zip-rar && \
    sudo apt autoremove -y

# setup executable launcher
RUN mkdir /root/Desktop && \
    echo "FONT_NAME=\"Cantarell\" FONT_SIZE=7.5 SCALEHACKX=1.0225 SCALEHACKY=1.01 LC_ALL=C MONO_IOMAP=all mono Aurora.exe" > /root/Aurora.sh && \
    chmod +x /root/Aurora.sh
COPY Aurora.desktop /root/Desktop/Aurora.desktop
