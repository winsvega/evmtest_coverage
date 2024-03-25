FROM ubuntu:20.04 as evmonecoverage

ARG PYSPECS_SRC="https://github.com/ethereum/execution-spec-tests"
ARG RETESTETH_SRC="https://github.com/ethereum/retesteth.git"
ARG EVMONE_SRC="https://github.com/ethereum/evmone.git"

# Leave empty to disable the build, can point to commit hash as well
ARG RETESTETH="develop"
ARG PYSPECS="main"
ARG EVMONE="master"

SHELL ["/bin/bash", "-c"]
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Get necessary packages
RUN apt-get update \
    && apt install software-properties-common -y \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && add-apt-repository -y ppa:deadsnakes/ppa  \
    && apt-get install --yes jq cpanminus libssl-dev libgmp-dev lsof git make perl psmisc curl wget gcc-11 g++-11 \
    && apt-get install --yes python3.10 python3.10-venv python3-pip python3-dev \
    && apt-get install --yes uuid-runtime \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get remove -y cmake && rm /usr/bin/gcc && rm /usr/bin/g++ && rm /usr/bin/gcov \
    && ln -s /usr/bin/gcc-11 /usr/bin/gcc \
    && ln -s /usr/bin/g++-11 /usr/bin/g++ \
    && ln -s /usr/bin/gcov-11 /usr/bin/gcov \
    && rm /usr/bin/python3 && ln -s /usr/bin/python3.10 /usr/bin/python3

# CMAKE LATEST
RUN wget https://github.com/Kitware/CMake/releases/download/v3.28.0/cmake-3.28.0.tar.gz \
    && tar -zxvf cmake-3.28.0.tar.gz && cd cmake-3.28.0 \
    && ./bootstrap && make -j6 && make install

# Evmone
RUN test -n "$EVMONE" \
     && git clone --recursive $EVMONE_SRC /evmone \
     && cd /evmone && git fetch && git checkout $evmone \
     && cmake -S . -B build -DEVMONE_TESTING=ON -DCMAKE_BUILD_TYPE=Coverage -DEVMONE_PRECOMPILES_SILKPRE=1 \
     && cmake --build build \
     && ln -s /evmone/build/bin/evmone-t8n /usr/bin/evmone \
     && ln -s /evmone/build/bin/evmone-statetest /usr/bin/evmone-statetest \
     && ln -s /evmone/build/bin/evmone-blockchaintest /usr/bin/evmone-blockchaintest \
     || echo "Evmone is empty"

# Retesteth
RUN test -n "$RETESTETH" \
    && git clone $RETESTETH_SRC /retesteth \
    && cd /retesteth && git fetch && git checkout $RETESTETH && mkdir /build && cd /build \
    && cmake /retesteth -DCMAKE_BUILD_TYPE=Release \
    && make -j6 \
    && cp /build/retesteth/retesteth /usr/bin/retesteth \
    && rm -rf /build /retesteth /var/cache/* /root/.hunter/* \
    || echo "Retesteth is empty" > /usr/bin/retesteth

# LCOV and SCRIPT
RUN wget https://github.com/linux-test-project/lcov/releases/download/v2.0/lcov-2.0.tar.gz \
    && tar -xvf lcov-2.0.tar.gz \
    && cpanm Capture::Tiny DateTime \
    && ln -s /lcov-2.0/bin/lcov /usr/bin/lcov \
    && ln -s /lcov-2.0/bin/genhtml /usr/bin/genhtml

# Pyspecs
RUN git clone $PYSPECS_SRC /execution-spec-tests 
RUN cd /execution-spec-tests && git fetch && git checkout $PYSPECS \
    && python3 -m venv ./venv/ \
    && source ./venv/bin/activate \
    && pip install -e . \
    && wget https://raw.githubusercontent.com/ethereum/retesteth/develop/web/tfinit.sh \
    && cp tfinit.sh /usr/bin/tfinit.sh \
    && chmod +x /usr/bin/tfinit.sh

ENTRYPOINT ["/usr/bin/bash"]
