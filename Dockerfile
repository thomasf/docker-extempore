FROM ubuntu:trusty

# based on an original dockerfile by Sébastien Rannou
MAINTAINER Ben Swift <benjamin.j.swift@gmail.com>

# get deps
# RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get update && apt-get upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
    git                                                  \
    binutils                                             \
    g++                                                  \
    wget                                                 \
    make                                                 \
    portaudio19-dev                                      \
    libpcre3-dev                                         \
    libgl1-mesa-dev                                      \
    libasound2                                           \
    python                                               \
    librtmidi1
RUN apt-get clean

# download extempore master branch
RUN git clone https://github.com/digego/extempore.git /extempore

# download, patch, and build LLVM
RUN wget -qO- http://llvm.org/releases/3.4.1/llvm-3.4.1.src.tar.gz | tar xvz

WORKDIR /llvm-3.4.1.src
RUN cd lib/AsmParser && patch < /extempore/extras/llparser.patch
RUN mkdir /llvm-build && ./configure --prefix=/llvm-build --disable-shared --enable-optimized --enable-targets=host --disable-bindings --enable-curses=no --enable-terminfo=no 
RUN make -j5 && make install && cd / && rm -rf /llvm-3.4.1.src

# build extempore
WORKDIR /extempore
# set LLVM environment var
ENV EXT_LLVM_DIR /llvm-build
RUN ./all.bash

# extempore primary process
EXPOSE 7098 
# extempore utility process
EXPOSE 7099 

ENTRYPOINT ["/extempore/extempore"]
