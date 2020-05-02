# https://hub.docker.com/r/dorowu/ubuntu-desktop-lxde-vnc/
FROM dorowu/ubuntu-desktop-lxde-vnc

# https://www.mono-project.com/download/preview/
RUN sudo apt update && \
    sudo apt install -y --no-install-recommends gnupg ca-certificates && \
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/ubuntu preview-bionic main" | sudo tee /etc/apt/sources.list.d/mono-official-preview.list && \
    sudo apt update && \
    sudo apt install -y --no-install-recommends mono-complete wget git-core fonts-cantarell p7zip-full p7zip-rar \
    # below are for compiling libgdiplus
    libgif-dev autoconf libtool automake build-essential gettext libglib2.0-dev libcairo2-dev libtiff-dev libexif-dev && \
    sudo apt purge firefox chromium-browser -y && \
    sudo apt autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Everything is setup and run as root.
# The 'working directory' for Docker commands and root is /root/

# copy any Aurora files you might already have over, prevents needing to download them again
COPY *.rar /root/

# download Aurora4x C#
# -nc prevents the file from being re-downloaded if it wasn't copied over
# https://stackoverflow.com/questions/4944295/skip-download-if-files-exist-in-wget
RUN wget -nc http://www.pentarch.org/steve/Aurora151Full.rar
# patches to apply
RUN wget -nc http://www.pentarch.org/steve/Aurora190.rar
RUN wget -nc http://www.pentarch.org/steve/Aurora193.rar

# md5sum *.rar
# 19113d9b9aef38858b8ca03a423be747  Aurora151Full.rar
# f23c7feb367ac0a7952292096ae58b0b  Aurora190.rar
# 0e7e7cc07e633eedc703783bfa9dfbfb  Aurora193.rar

# extract Aurora4x from the .rars, -y option accepts overwrites of files from the patches
RUN 7z x Aurora151Full.rar && \
    7z x Aurora190.rar -y && \
    7z x Aurora193.rar -y && \
    rm *.rar


# TODO: build libgdiplus
# https://github.com/mono/libgdiplus
RUN git clone --recursive https://github.com/mono/libgdiplus.git
WORKDIR ./libgdiplus/
RUN ./autogen.sh && \
    make && \
    make install

WORKDIR ../

# TODO: apply cpw scaling patch overtop Mono master, build mono, install or copy over needed files



# COPY lib/AuroraLinuxLibs.zip /root/AuroraLinuxLibs.zip
# RUN 7z x AuroraLinuxLibs.zip -y
# COPY lib/libgdiplus.so.0 /root/libgdiplus.so.0
# COPY lib/libSQLite.Interop.so /root/libSQLite.Interop.so
# COPY lib/SQLite.Interop.dll /root/SQLite.Interop.dll
# COPY lib/System.Data.Entity.Design.dll /root/System.Data.Entity.Design.dll



# TODO: remove llvm? mono-docs?
# use wajig to find large packages that are left dangling that could be removed to save space
# $ apt update && apt install wajig
# $ wajig large
# RUN sudo apt purge mono-devl msbuild libgif-dev autoconf libtool automake \
#     build-essential gettext libglib2.0-dev libcairo2-dev libtiff-dev libexif-dev -y && \
#     sudo apt autoremove -y

# setup executable launcher
RUN mkdir /root/Desktop && \
    echo "FONT_NAME=\"Cantarell\" FONT_SIZE=7.5 SCALEHACKX=1.0225 SCALEHACKY=1.01 LC_ALL=C MONO_IOMAP=all mono Aurora.exe" > /root/Aurora.sh && \
    chmod +x /root/Aurora.sh
COPY Aurora.desktop /root/Desktop/Aurora.desktop
