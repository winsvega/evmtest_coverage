FROM ubuntu:20.04 as evmonecoverage

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
    && apt-get install --yes jq cpanminus lsof git cmake make perl psmisc curl wget gcc-11 g++-11 \
    && apt-get install --yes uuid-runtime \
    && rm -rf /var/lib/apt/lists/*
RUN rm /usr/bin/gcc && rm /usr/bin/gcov \
    && ln -s /usr/bin/gcc-11 /usr/bin/gcc \
    && ln -s /usr/bin/g++-11 /usr/bin/g++ \
    && ln -s /usr/bin/gcov-11 /usr/bin/gcov


# Evmone
RUN test -n "$EVMONE" \
     && git clone --recursive $EVMONE_SRC /evmone \
     && cd /evmone && git fetch && git checkout $evmone \
     && cmake -S . -B build -DEVMONE_TESTING=ON -DCMAKE_BUILD_TYPE=Coverage \
     && cmake --build build \
     && ln -s /evmone/build/bin/evmone-t8n /usr/bin/evmone \
    || echo "Evmone is empty"

# Retesteth
RUN test -n "$RETESTETH" \
    && git clone $RETESTETH_SRC /retesteth \
    && cd /retesteth && git fetch && git checkout $RETESTETH && mkdir /build && cd /build \
    && cmake /retesteth -DCMAKE_BUILD_TYPE=Release \
    && make -j2 \
    && cp /build/retesteth/retesteth /usr/bin/retesteth \
    && rm -rf /build /retesteth /var/cache/* /root/.hunter/* \
    || echo "Retesteth is empty" > /usr/bin/retesteth

# LCOV and SCRIPT
RUN wget https://github.com/linux-test-project/lcov/releases/download/v2.0/lcov-2.0.tar.gz \
    && tar -xvf lcov-2.0.tar.gz \
    && cpanm Capture::Tiny DateTime \
    && ln -s /lcov-2.0/bin/lcov /usr/bin/lcov \
    && ln -s /lcov-2.0/bin/genhtml /usr/bin/genhtml

RUN wget https://raw.githubusercontent.com/winsvega/evmtest_coverage/main/evmone_coverage.sh \
    && cp evmone_coverage.sh /usr/bin/evmone_coverage.sh \
    && chmod +x /usr/bin/evmone_coverage.sh

ENTRYPOINT ["/usr/bin/evmone_coverage.sh"]
