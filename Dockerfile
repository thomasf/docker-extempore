FROM debian:testing

# based on an original dockerfile by Sébastien Rannou
MAINTAINER Ben Swift <benjamin.j.swift@gmail.com>

# get deps (listed in alphabetical order)
RUN apt-get update --yes && apt-get install --yes \
    binutils                                      \
    curl                                          \
    g++                                           \
    libasound2                                    \
    libgl1-mesa-dev                               \
    libpcre3-dev                                  \
    make                                          \
    libnanomsg0                                   \
    patch                                         \
    portaudio19-dev                               \
    python                                        \
    unzip &&                                      \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# download, patch, and build LLVM
RUN curl -O http://llvm.org/releases/3.4.1/llvm-3.4.1.src.tar.gz &&                                                 \
    tar -xf llvm-3.4.1.src.tar.gz &&                                                                                \
    cd /llvm-3.4.1.src/lib/AsmParser &&                                                                             \
    curl -s curl -s https://raw.githubusercontent.com/digego/extempore/master/extras/llparser.patch | patch -i - && \
    cd /llvm-3.4.1.src &&                                                                                           \
    mkdir /llvm-build &&                                                                                            \
    ./configure --prefix=/llvm-build                                                                                \
                --disable-shared                                                                                    \
                --enable-optimized                                                                                  \
                --enable-targets=host                                                                               \
                --disable-bindings                                                                                  \
                --enable-curses=no                                                                                  \
                --enable-terminfo=no  &&                                                                            \
    make install &&                                                                                                 \
    cd / &&                                                                                                         \
    rm -rf /llvm-3.4.1.src

# which GitHub branch to build Extempore from
ENV EXTEMPORE_GH_BRANCH master

WORKDIR /opt/

# download kiss_fft
RUN curl -L -o source.zip http://github.com/benswift/kiss_fft/zipball/master/ && \
    unzip source.zip && \
    mv $(ls | grep kiss_fft) kiss_fft && \
    rm source.zip # cache-busting comment

WORKDIR /opt/kiss_fft

run gcc kiss_fft.c tools/kiss_fftr.c -fPIC -shared -I. -I/usr/include/malloc -o kiss_fft.1.3.0.so && \
    mv kiss_fft.1.3.0.so /usr/lib/ && \
    ln -s /usr/lib/kiss_fft.1.3.0.so /usr/lib/kiss_fft.so

WORKDIR /

# download extempore
RUN curl -L -o source.zip http://github.com/digego/extempore/zipball/$EXTEMPORE_GH_BRANCH/ && \
    unzip source.zip &&                                                                       \
    mv $(ls | grep extempore) extempore &&                                                    \
    rm source.zip # cache-busting comment

WORKDIR extempore

# set LLVM environment var
ENV EXT_LLVM_DIR /llvm-build
# build extempore
RUN ./all.bash

# TODO: move this up to the other apt-get's later
run apt-get update --yes && apt-get install --yes libsndfile1-dev librtmidi-dev

WORKDIR /opt/

# download rtmidi
RUN curl -L -o source.zip http://github.com/benswift/rtmidi/zipball/master/ && \
    unzip source.zip && \
    mv $(ls | grep rtmidi) rtmidi && \
    rm source.zip # cache-busting comment

WORKDIR /opt/rtmidi
run ./make-rtmidic.sh && mv librtmidic.so /usr/lib


WORKDIR /extempore
# build the stdlib (comment out if you don't want it)
# RUN PRECOMP_LIBS="core/std.xtm core/math.xtm" ./compile-stdlib.sh --noaudio
RUN PRECOMP_LIBS="core/std.xtm \
core/math.xtm \
core/audio_dsp.xtm \
core/instruments.xtm \
external/fft.xtm \
external/sndfile.xtm \
external/audio_dsp_ext.xtm \
external/instruments_ext.xtm \
external/rtmidi.xtm" ./compile-stdlib.sh --noaudio


RUN rm -rf /opt/

# remove build-time deps from image
RUN apt-get remove --purge --yes \
    binutils                     \
    curl                         \
    g++                          \
    libpcre3-dev                 \
    make                         \
    patch                        \
    python                       \
    unzip
    
# extempore primary & utility process ports, plus nanomsg port
EXPOSE 7099 7098 7199

ENTRYPOINT ["/extempore/extempore"]
