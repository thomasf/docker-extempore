FROM debian:wheezy

# based on an original dockerfile by Sébastien Rannou
MAINTAINER Ben Swift <benjamin.j.swift@gmail.com>

# get deps
RUN apt-get update --yes && apt-get upgrade --yes && apt-get install --yes \
    binutils                                             \
    g++                                                  \
    curl                                                 \
    patch                                                \
    make                                                 \
    unzip                                                \
    portaudio19-dev                                      \
    libpcre3-dev                                         \
    libgl1-mesa-dev                                      \
    libasound2                                           \
    python                                               \
    librtmidi1 &&                                        \
    apt-get clean

# download, patch, and build LLVM
RUN curl -O http://llvm.org/releases/3.4.1/llvm-3.4.1.src.tar.gz &&                                                                                           \
    tar -xf llvm-3.4.1.src.tar.gz &&                                                                                                                          \
    cd /llvm-3.4.1.src/lib/AsmParser &&                                                                                                                       \
    curl -s curl -s https://raw.githubusercontent.com/digego/extempore/master/extras/llparser.patch | patch -i - &&                                                                                                               \
    cd /llvm-3.4.1.src &&                                                                                                                                     \
    mkdir /llvm-build &&                                                                                                                                      \
    ./configure --prefix=/llvm-build --disable-shared --enable-optimized --enable-targets=host --disable-bindings --enable-curses=no --enable-terminfo=no  && \
    make install &&                                                                                                                                           \
    cd / &&                                                                                                                                                   \
    rm -rf /llvm-3.4.1.src

# download extempore
RUN curl -L -o source.zip http://github.com/digego/extempore/zipball/nodevice-audio/ && unzip source.zip && mv $(ls | grep extempore) extempore && rm source.zip # cache-busting comment

# set LLVM environment var
ENV EXT_LLVM_DIR /llvm-build
# build extempore
RUN cd /extempore && ./all.bash

# extempore primary process
EXPOSE 7098 
# extempore utility process
EXPOSE 7099 

ENTRYPOINT ["/extempore/extempore"]
