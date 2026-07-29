# syntax=docker/dockerfile:1.7

ARG DEBIAN_IMAGE=debian:13.6-slim@sha256:020c0d20b9880058cbe785a9db107156c3c75c2ac944a6aa7ab59f2add76a7bd

FROM ${DEBIAN_IMAGE} AS build

ARG BUILD_JOBS=4
ARG LIBTORRENT_VERSION=1.2.20
ARG LIBTORRENT_SHA256=ccbf8e8c21dc81635de95166b498922b4725f9725a23b2cfe2a6b2fead6fb9fc
ARG QBITTORRENT_VERSION=5.2.3
ARG QBITTORRENT_SHA256=7573621859da7287ba708378ea9f5eb12f30962a1a7c28eba5f44ecf8c4c114c

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /build

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        libboost-dev \
        libssl-dev \
        ninja-build \
        pkg-config \
        qt6-base-dev \
        qt6-base-private-dev \
        qt6-tools-dev \
        xz-utils \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo libtorrent.tar.gz \
        "https://github.com/arvidn/libtorrent/releases/download/v${LIBTORRENT_VERSION}/libtorrent-rasterbar-${LIBTORRENT_VERSION}.tar.gz" \
    && echo "${LIBTORRENT_SHA256}  libtorrent.tar.gz" | sha256sum -c - \
    && tar -xzf libtorrent.tar.gz \
    && cmake -G Ninja \
        -S "libtorrent-rasterbar-${LIBTORRENT_VERSION}" \
        -B libtorrent-build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DCMAKE_CXX_STANDARD=17 \
        -Dbuild_examples=OFF \
        -Dbuild_tests=OFF \
        -Dbuild_tools=OFF \
        -Dpython-bindings=OFF \
    && cmake --build libtorrent-build --parallel "${BUILD_JOBS}" \
    && cmake --install libtorrent-build \
    && ldconfig \
    && rm -rf libtorrent.tar.gz "libtorrent-rasterbar-${LIBTORRENT_VERSION}" libtorrent-build

RUN curl -fsSLo qbittorrent.tar.xz \
        "https://github.com/qbittorrent/qBittorrent/releases/download/release-${QBITTORRENT_VERSION}/qbittorrent-${QBITTORRENT_VERSION}.tar.xz" \
    && echo "${QBITTORRENT_SHA256}  qbittorrent.tar.xz" | sha256sum -c - \
    && tar -xJf qbittorrent.tar.xz \
    && cmake -G Ninja \
        -S "qbittorrent-${QBITTORRENT_VERSION}" \
        -B qbittorrent-build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DGUI=OFF \
        -DSTACKTRACE=OFF \
        -DSYSTEMD=OFF \
    && cmake --build qbittorrent-build --parallel "${BUILD_JOBS}" \
    && cmake --install qbittorrent-build \
    && strip --strip-unneeded /usr/local/bin/qbittorrent-nox \
    && find /usr/local/lib -type f -name 'libtorrent-rasterbar.so*' -exec strip --strip-unneeded {} + \
    && rm -rf qbittorrent.tar.xz "qbittorrent-${QBITTORRENT_VERSION}" qbittorrent-build

FROM ${DEBIAN_IMAGE}

ARG QBITTORRENT_VERSION=5.2.3

LABEL org.opencontainers.image.title="qBittorrent VPN" \
      org.opencontainers.image.description="qBittorrent with OpenVPN, WireGuard, and an iptables killswitch" \
      org.opencontainers.image.version="${QBITTORRENT_VERSION}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /opt

RUN usermod -u 99 nobody \
    && mkdir -p /downloads /config/qBittorrent /etc/openvpn /etc/qbittorrent \
    && sed -i 's/^Components: main$/Components: main non-free/' /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        7zip \
        ca-certificates \
        dos2unix \
        inetutils-ping \
        ipcalc \
        iproute2 \
        iptables \
        kmod \
        libqt6network6 \
        libqt6sql6 \
        libqt6sql6-sqlite \
        libqt6xml6 \
        libssl3t64 \
        moreutils \
        net-tools \
        openresolv \
        openssl \
        openvpn \
        procps \
        unrar \
        unzip \
        wireguard-tools \
        zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=build /usr/local/bin/qbittorrent-nox /usr/local/bin/qbittorrent-nox
COPY --from=build /usr/local/lib/libtorrent-rasterbar.so.1.2.20 /usr/local/lib/

COPY openvpn/ /etc/openvpn/
COPY qbittorrent/ /etc/qbittorrent/

RUN ln -s libtorrent-rasterbar.so.1.2.20 /usr/local/lib/libtorrent-rasterbar.so.10 \
    && ln -s libtorrent-rasterbar.so.10 /usr/local/lib/libtorrent-rasterbar.so \
    && ldconfig \
    && sed -i '/net\.ipv4\.conf\.all\.src_valid_mark/d' "$(command -v wg-quick)" \
    && chmod +x /etc/qbittorrent/*.sh /etc/qbittorrent/*.init /etc/openvpn/*.sh \
    && qbittorrent-nox --version

VOLUME ["/config", "/downloads"]

EXPOSE 8080 8999/tcp 8999/udp

STOPSIGNAL SIGTERM
CMD ["/bin/bash", "/etc/openvpn/start.sh"]
