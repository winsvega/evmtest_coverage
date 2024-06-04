FROM ubuntu:20.04 as evmone-coverage

ARG EVMONE_SRC="https://github.com/ethereum/evmone.git"
ARG EVMONE="master"

SHELL ["/bin/bash", "-c"]
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Get necessary packages
RUN apt-get update \
    && apt install software-properties-common -y \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && add-apt-repository -y ppa:deadsnakes/ppa  \
    && apt-get install --yes gcc-11 g++-11 wget git \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get remove -y cmake  \
    && ln -s /usr/bin/gcc-11 /usr/bin/gcc \
    && ln -s /usr/bin/g++-11 /usr/bin/g++ \
    && ln -s /usr/bin/gcov-11 /usr/bin/gcov

# CMAKE LATEST
RUN apt-get update \
    && apt-get install --yes make libssl-dev
RUN wget https://github.com/Kitware/CMake/releases/download/v3.28.0/cmake-3.28.0.tar.gz \
    && tar -zxvf cmake-3.28.0.tar.gz && cd cmake-3.28.0 \
    && ./bootstrap && make -j6 && make install

# Evmone
RUN apt-get update \
    && apt-get install --yes libgmp-dev
RUN test -n "$EVMONE" \
     && git clone --recursive $EVMONE_SRC /evmone \
     && cd /evmone && git fetch && git checkout $evmone \
     && cmake -S . -B build -DEVMONE_TESTING=ON -DCMAKE_BUILD_TYPE=Coverage -DEVMONE_PRECOMPILES_SILKPRE=1 \
     && cmake --build build \
     && ln -s /evmone/build/bin/evmone-t8n /usr/bin/evmone-t8n \
     && ln -s /evmone/build/bin/evmone-statetest /usr/bin/evmone-statetest \
     && ln -s /evmone/build/bin/evmone-blockchaintest /usr/bin/evmone-blockchaintest \
     && ln -s /evmone/build/bin/evmone-eoftest /usr/bin/evmone-eoftest \
     && ln -s /evmone/build/bin/evmone-eofparse /usr/bin/evmone-eofparse \
     || echo "Evmone is empty"


# LCOV
RUN apt-get install --yes cpanminus perl psmisc \
    && ln -s /usr/bin/x86_64-linux-gnu-gcc-11 /usr/bin/x86_64-linux-gnu-gcc \
    && ln -s /usr/bin/gcov-dump-11 /usr/bin/gcov-dump \
    && ln -s /usr/bin/gcov-tool-11 /usr/bin/gcov-tool

RUN wget https://github.com/linux-test-project/lcov/releases/download/v2.0/lcov-2.0.tar.gz \
    && tar -xvf lcov-2.0.tar.gz \
    && cpanm Capture::Tiny DateTime \
    && ln -s /lcov-2.0/bin/lcov /usr/bin/lcov \
    && ln -s /lcov-2.0/bin/genhtml /usr/bin/genhtml

ENTRYPOINT ["/usr/bin/bash"]
