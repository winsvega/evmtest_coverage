FROM ubuntu:20.04 as retesteth-develop

ARG RETESTETH_SRC="https://github.com/ethereum/retesteth.git"
ARG RETESTETH="develop"

SHELL ["/bin/bash", "-c"]
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Get necessary packages
RUN apt-get update \
    && apt install software-properties-common -y \
    && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
    && add-apt-repository -y ppa:deadsnakes/ppa  \
    && apt-get install --yes gcc-11 g++-11 wget git cmake  \
    && rm -rf /var/lib/apt/lists/*

RUN rm /usr/bin/gcc \
    && ln -s /usr/bin/gcc-11 /usr/bin/gcc \
    && ln -s /usr/bin/g++-11 /usr/bin/g++ 

# Retesteth
RUN test -n "$RETESTETH" \
    && git clone $RETESTETH_SRC /retesteth \
    && cd /retesteth \
    && git fetch && git checkout $RETESTETH && git submodule update --init --recursive \
    && mkdir /build && cd /build \
    && cmake /retesteth -DCMAKE_BUILD_TYPE=Release \
    && make -j6 \
    && cp /build/retesteth/retesteth /usr/bin/retesteth \
    && rm -rf /build /retesteth /var/cache/* /root/.hunter/* \
    || echo "Retesteth is empty" > /usr/bin/retesteth


ENTRYPOINT ["/usr/bin/retesteth"]
