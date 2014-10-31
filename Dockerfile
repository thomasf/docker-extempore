FROM debian:testing

# based on an original dockerfile by Sébastien Rannou
MAINTAINER Ben Swift <benjamin.j.swift@gmail.com>

# which GitHub branch to build Extempore from
ENV EXTEMPORE_GH_BRANCH nodevice-audio

# get deps (listed in alphabetical order)
RUN apt-get update --yes && apt-get install --yes \
    binutils                                      \
    curl                                          \
    g++                                           \
    libasound2                                    \
    libgl1-mesa-dev                               \
    libpcre3-dev                                  \
    make                                          \
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

# download and build nanomsg (filthy hack - should be it's own container)
RUN curl -L -o source.tar.gz http://download.nanomsg.org/nanomsg-0.4-beta.tar.gz && \
    tar xvf source.tar.gz &&                                                        \
    mv $(ls | grep nanomsg) nanomsg &&                                              \
    rm source.tar.gz &&                                                             \
    cd nanomsg &&                                                                   \
    ./configure &&                                                                  \
    make &&                                                                         \
    cp .libs/libnanomsg.so.0.2.0 /usr/local/lib &&                                  \
    ln -s /usr/local/lib/libnanomsg.so.0.2.0 /usr/local/lib/libnanomsg.so &&        \
    cd / && rm -r nanomsg

# download extempore
RUN curl -L -o source.zip http://github.com/digego/extempore/zipball/$EXTEMPORE_GH_BRANCH/ && \
    unzip source.zip &&                                                                       \
    mv $(ls | grep extempore) extempore &&                                                    \
    rm source.zip

WORKDIR extempore

# set LLVM environment var
ENV EXT_LLVM_DIR /llvm-build
# build extempore
RUN ./all.bash

# build the stdlib (comment out if you don't want it)
RUN PRECOMP_LIBS="core/std.xtm core/math.xtm" ./compile-stdlib.sh

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
