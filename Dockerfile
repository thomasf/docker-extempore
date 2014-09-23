FROM debian:wheezy

# based on an original dockerfile by Sébastien Rannou
MAINTAINER Ben Swift <benjamin.j.swift@gmail.com>

# get deps
RUN apt-get update && apt-get upgrade && DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
    # git                                                  \
    binutils                                             \
    g++                                                  \
    curl                                                 \
    make                                                 \
    unzip                                                \
    portaudio19-dev                                      \
    libpcre3-dev                                         \
    libgl1-mesa-dev                                      \
    libasound2                                           \
    python                                               \
    librtmidi1 &&                                        \
    apt-get clean

# download extempore
RUN curl -L -o extempore.zip http://github.com/digego/extempore/zipball/nodevice-audio/ && unzip extempore.zip && mv $(ls | grep extempore) extempore
# download, patch, and build LLVM
RUN curl -O http://llvm.org/releases/3.4.1/llvm-3.4.1.src.tar.gz &&                                                                                           \
    tar -xf llvm-3.4.1.src.tar.gz &&                                                                                                                          \
    cd /llvm-3.4.1.src/lib/AsmParser &&                                                                                                                       \
    patch < /extempore/extras/llparser.patch &&                                                                                                               \
    cd /llvm-3.4.1.src &&                                                                                                                                     \
    mkdir /llvm-build &&                                                                                                                                      \
    ./configure --prefix=/llvm-build --disable-shared --enable-optimized --enable-targets=host --disable-bindings --enable-curses=no --enable-terminfo=no  && \
    make install &&                                                                                                                                           \
    cd / &&                                                                                                                                                   \
    rm -rf /llvm-3.4.1.src

# set LLVM environment var
ENV EXT_LLVM_DIR /llvm-build
# build extempore
RUN cd /extempore && ./all.bash

# extempore primary process
EXPOSE 7098 
# extempore utility process
EXPOSE 7099 

ENTRYPOINT ["/extempore/extempore"]
