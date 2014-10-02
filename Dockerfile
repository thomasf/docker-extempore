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
    patch                                         \
    portaudio19-dev                               \
    python                                        \
    unzip &&                                      \
    apt-get clean

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

# download extempore
RUN curl -L -o source.zip http://github.com/digego/extempore/zipball/nodevice-audio/ && \
    unzip source.zip &&                                                                 \
    mv $(ls | grep extempore) extempore &&                                              \
    rm source.zip

# set LLVM environment var
ENV EXT_LLVM_DIR /llvm-build
# build extempore
RUN cd /extempore && ./all.bash

# extempore primary process
EXPOSE 7098 
# extempore utility process
EXPOSE 7099 

ENTRYPOINT ["/extempore/extempore"]
