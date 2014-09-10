FROM ubuntu:trusty

# based on an original dockerfile by Sébastien Rannou
MAINTAINER Ben Swift <benjamin.j.swift@gmail.com>

# get deps
RUN apt-get update && apt-get upgrade
RUN DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
    git				   		    \
    binutils						\
    g++									\
    wget								\
    make								\
    portaudio19-dev			\
    libpcre3-dev				\
    mesa-common-dev			\
    libgl1-mesa-dev			\
    jackd								\
    librtmidi1					\
    lame								\
    vlc									\
    libavcodec-extra-54	\
    vlc-plugin-jack &&	\
    apt-get clean

# download extempore master branch
RUN git clone https://github.com/digego/extempore.git /extempore

# download, patch, and build LLVM
RUN wget -qO- http://llvm.org/releases/3.4.1/llvm-3.4.1.src.tar.gz | tar xvz && \
    cd /llvm-3.4.1.src/lib/AsmParser &&                    \
    patch < /extempore/extras/llparser.patch &&            \
    cd /llvm-3.4.1.src &&                                  \
    mkdir /llvm-build &&                                   \
    ./configure --prefix=/llvm-build --enable-optimized && \
    make -j5 &&                                            \
    make install &&                                        \
    rm -rf /llvm-3.4.1.src

# set LLVM environment var
ENV EXT_LLVM_DIR /llvm-build

# build extempore
WORKDIR /extempore
RUN ./all.bash

# extempore primary process
EXPOSE 7098 
# extempore utility process
EXPOSE 7099 
# jack streaming port
EXPOSE 8080 

# RUN adduser --system --shell /bin/bash --disabled-password --home /extempore extempore
# RUN chmod -R extempore /extempore
# USER extempore

RUN jackd --no-realtime -d dummy -r 44100 &
RUN sleep 1
RUN cvlc -vvv 'jack://channels=2:ports=.*' --sout '#transcode{acodec=mp3,ab=256,channels=2,samplerate=44100}:std{access=http,mux=mp3,dst=:8080}' &

ENTRYPOINT ["/extempore"]
