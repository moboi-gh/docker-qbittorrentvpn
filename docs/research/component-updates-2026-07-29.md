# Component update audit — 2026-07-29

## Scope and conclusion

This is an audit of the externally versioned components selected by this repository. The repository has no prior research-note convention, so this note lives under `docs/research/`. No implementation changes are included.

The important result is that qBittorrent cannot be upgraded in isolation. [`Dockerfile:139-144`](../../Dockerfile#L139-L144) already resolves the current stable tag, `release-5.2.3`, but the build is blocked earlier by the Boost download and would later fail qBittorrent's Qt 6/OpenSSL 3 requirements. The safe baseline is a coordinated move from Debian 11 to Debian 13, plus explicit versions instead of “latest” API/RSS selectors.

The upstream repository is also [archived](https://api.github.com/repos/DyonR/docker-qbittorrentvpn), and the local `master` is from September 2022. This is therefore fork maintenance, not a routine dependency bump.

The actual published `latest` artifact is older than today's dynamic selectors. Docker Hub reports the amd64-only image digest `sha256:d5c50beb560880303cfa4144411ab04311134d6c2c052a0e6a97b93441b5e3c6`, pushed on 2023-11-01 ([tag API](https://hub.docker.com/v2/repositories/dyonr/qbittorrentvpn/tags/latest)). Direct inspection during this audit found qBittorrent 4.6.0, libtorrent 1.2.19, Boost 1.83, CMake 3.28.0-rc3, Ninja 1.11.1, Qt 5.15.2, OpenSSL 1.1.1w, and OpenVPN 2.5.1. Thus “current source selector,” “last published image,” and “proposed pin” are three different states.

## Current selectors and proposed versions

| Component | Current location and behavior on 2026-07-29 | Proposed conservative version | Optional newer track |
|---|---|---|---|
| Debian | [`Dockerfile:2`](../../Dockerfile#L2) uses mutable `debian:bullseye-slim`, currently Debian 11.11. | `debian:trixie-20260713-slim` (Debian 13.6), or `13.6-slim` if rolling point-release updates are wanted. The [Docker Official Images manifest](https://github.com/docker-library/official-images/blob/master/library/debian) lists all of these tags. | Pin the multi-architecture manifest digest as well when reproducibility matters. |
| Boost | [`Dockerfile:12-38`](../../Dockerfile#L12-L38) parses the Boost news RSS. The exact pipeline now returns an empty version. Its JFrog download URL redirects to an HTML “reactivate server” page. | Use Debian Trixie's `libboost-dev` 1.83.0.2; this satisfies qBittorrent's minimum. [Debian package](https://packages.debian.org/trixie/libboost-dev). | Boost 1.91.0 from the [official Boost archive](https://archives.boost.io/release/1.91.0/source/), SHA-256 `5734305f40a76c30f951c9abd409a45a2a19fb546efe4162119250bbe4d3a463` from [Boost's artifact metadata](https://archives.boost.io/release/1.91.0/source/boost_1_91_0.tar.gz.json). |
| Ninja | [`Dockerfile:40-65`](../../Dockerfile#L40-L65) currently resolves v1.13.2, but `match("ninja-linux")` returns both `ninja-linux-aarch64.zip` and `ninja-linux.zip`; the first downloaded archive is currently ARM64 even in an amd64 build. | Debian Trixie `ninja-build` 1.12.1. [Debian package](https://packages.debian.org/trixie/ninja-build). | Pin v1.13.2 and choose one asset from `TARGETARCH`. Official [release](https://github.com/ninja-build/ninja/releases/tag/v1.13.2) and [asset API](https://api.github.com/repos/ninja-build/ninja/releases/tags/v1.13.2). SHA-256: amd64 `5749cbc4e668273514150a80e387a957f933c6ed3f5f11e03fb30955e2bbead6`; arm64 `fd2cacc8050a7f12a16a2e48f9e06fca5c14fc4c2bee2babb67b58be17a607fc`. |
| CMake | [`Dockerfile:67-89`](../../Dockerfile#L67-L89) currently resolves v4.4.1, but hard-codes the `Linux-x86_64.sh` asset. | Debian Trixie CMake 3.31.6. [Debian package](https://packages.debian.org/trixie/cmake). | Pin CMake 4.4.1 and map `TARGETARCH` to the official amd64/arm64 installers. [Release](https://github.com/Kitware/CMake/releases/tag/v4.4.1); [official hashes](https://github.com/Kitware/CMake/releases/download/v4.4.1/cmake-4.4.1-SHA-256.txt). |
| libtorrent | [`Dockerfile:91-123`](../../Dockerfile#L91-L123) filters release metadata for `target_commitish == RC_1_2`; today it selects v1.2.19. | Pin v1.2.20 explicitly. It preserves the main image's documented 1.x behavior and is supported by qBittorrent 5.2.3. [Official release](https://github.com/arvidn/libtorrent/releases/tag/v1.2.20). | v2.0.13 is the newest supported 2.0.x release. Do **not** use v2.1.0: qBittorrent 5.2.3's supported range ends at 2.0.x. [v2.0.13 release](https://github.com/arvidn/libtorrent/releases/tag/v2.0.13), [v2.1.0 release](https://github.com/arvidn/libtorrent/releases/tag/v2.1.0). |
| qBittorrent | [`Dockerfile:125-165`](../../Dockerfile#L125-L165) is not pinned; its tag query currently returns `release-5.2.3`. | Pin qBittorrent 5.2.3 using the official `qbittorrent-5.2.3.tar.xz`, SHA-256 `7573621859da7287ba708378ea9f5eb12f30962a1a7c28eba5f44ecf8c4c114c`. [Official release](https://github.com/qbittorrent/qBittorrent/releases/tag/release-5.2.3). | None newer as of this audit. |
| OpenVPN | Installed without a version at [`Dockerfile:167-193`](../../Dockerfile#L167-L193); Bullseye supplies 2.5.1-3+deb11u4. | Trixie stable 2.6.14-1+deb13u3. It contains July 2026 security backports from 2.6.21. [Package](https://packages.debian.org/trixie/openvpn), [Debian changelog](https://metadata.ftp-master.debian.org/changelogs/main/o/openvpn/openvpn_2.6.14-1+deb13u3_changelog). | Trixie-backports has 2.7.5-1~bpo13+1, but use it only after VPN-provider configuration testing. [Backports package](https://packages.debian.org/trixie-backports/openvpn). |
| WireGuard tools | Installed without a version from a mixed-in `unstable` source at [`Dockerfile:167-193`](../../Dockerfile#L167-L193). Bullseye itself supplies 1.0.20210223-1. | Remove the `unstable` source and use Trixie stable 1.0.20210914-3. [Package](https://packages.debian.org/trixie/wireguard-tools). | Trixie-backports has 1.0.20250521; upstream has tagged 1.0.20260223. [Backports package](https://packages.debian.org/trixie-backports/wireguard-tools), [official upstream tags](https://git.zx2c4.com/wireguard-tools/refs/tags/). |
| Python search runtime | [`qbittorrent/install-python3.sh:4-11`](../../qbittorrent/install-python3.sh#L4-L11) installs an unpinned Python at container startup. Bullseye supplies 3.9.2. | Trixie supplies Python 3.13.5, which meets qBittorrent's optional-search minimum of 3.9. [Package](https://packages.debian.org/trixie/python3). Prefer image-build installation over mutable startup-time `apt`. | None needed. |
| Archive tools | [`Dockerfile:195-210`](../../Dockerfile#L195-L210) uses Bullseye `unrar`, `p7zip-full`, `unzip`, and `zip`. | Trixie `unrar` 7.1.8; replace transitional `p7zip-full` with `7zip` 25.01. [unrar](https://packages.debian.org/trixie/unrar), [p7zip-full dependency on 7zip](https://packages.debian.org/trixie/p7zip-full), [7zip](https://packages.debian.org/trixie/7zip). | None needed. |

### Why the libtorrent selector is stuck

The official [v1.2.20 release API](https://api.github.com/repos/arvidn/libtorrent/releases/tags/v1.2.20) reports `target_commitish: RC_2_0`, even though the tag and release notes are for 1.2.20 and describe RC_1_2 backports. Because [`Dockerfile:100`](../../Dockerfile#L100) requires the metadata value `RC_1_2`, it skips 1.2.20 and falls back to 1.2.19. Select a tag/version directly instead of treating mutable release metadata as a branch oracle.

### qBittorrent 5.2.3's dependency gate

The tagged qBittorrent source declares and enforces:

- Boost >= 1.76
- Qt 6.6.0 through 6.x
- OpenSSL >= 3.0.2
- libtorrent 1.2.19 through 1.2.x, or 2.0.10 through 2.0.x
- zlib >= 1.2.11
- CMake >= 3.16
- Python >= 3.9 only for the optional search engine
- C++20

Sources: [qBittorrent 5.2.3 INSTALL](https://github.com/qbittorrent/qBittorrent/blob/release-5.2.3/INSTALL#L4-L27), [enforced package checks](https://github.com/qbittorrent/qBittorrent/blob/release-5.2.3/cmake/Modules/CheckPackages.cmake#L39-L54), and [C++20 target feature](https://github.com/qbittorrent/qBittorrent/blob/release-5.2.3/cmake/Modules/CommonConfig.cmake#L15-L20). The changelog records the Qt 5/OpenSSL 1/C++17 break at [lines 480-482](https://github.com/qbittorrent/qBittorrent/blob/release-5.2.3/Changelog#L480-L482), followed by dropping Qt 6.5 at [line 193](https://github.com/qbittorrent/qBittorrent/blob/release-5.2.3/Changelog#L193).

The current image cannot meet that gate:

| Dependency | Bullseye/current Dockerfile | Bookworm | Trixie 13.6 | qBittorrent 5.2.3 minimum |
|---|---:|---:|---:|---:|
| Qt | Qt 5.15.2; Dockerfile explicitly installs Qt 5 | Qt 6.4.2 | Qt 6.8.2 | Qt 6.6.0 |
| OpenSSL development package | 1.1.1w | 3.0.20 | 3.5.6 | 3.0.2 |
| Default Boost development package | 1.74 | 1.74 | 1.83 | 1.76 |

Primary package pages: Bullseye [Qt 5](https://packages.debian.org/bullseye/qtbase5-dev) and [OpenSSL](https://packages.debian.org/bullseye/libssl-dev); Bookworm [Qt 6](https://packages.debian.org/bookworm/qt6-base-dev), [OpenSSL](https://packages.debian.org/bookworm/libssl-dev), and [Boost](https://packages.debian.org/bookworm/libboost-dev); Trixie [Qt 6](https://packages.debian.org/trixie/qt6-base-dev), [OpenSSL](https://packages.debian.org/trixie/libssl-dev), and [Boost](https://packages.debian.org/trixie/libboost-dev).

Bookworm is therefore not a supported middle step: its Qt and default Boost are below qBittorrent's declared minima. Trixie satisfies all three from its stable repository. Two clean arm64 `debian:trixie-slim` full builds performed during this audit succeeded for `release-5.2.3`: one used Trixie's libtorrent 2.0.11, and the preservation track source-built libtorrent 1.2.20 against Trixie's Boost 1.83/OpenSSL 3.5 before linking qBittorrent to `libtorrent-rasterbar.so.10`. Reported component versions were verified after both builds. The qBittorrent build needed `qt6-base-dev`, `qt6-base-private-dev`, and `qt6-tools-dev`. This proves both arm64 compilation paths, but not runtime, VPN, or killswitch behavior.

Debian 11 is also near end of life: Bullseye LTS ends on 2026-08-31 according to Debian's [LTS schedule](https://wiki.debian.org/LTS), while Debian's [release page](https://www.debian.org/releases/) identifies Trixie 13.6 as current stable. More urgently, Debian's [OpenVPN security tracker](https://security-tracker.debian.org/tracker/source-package/openvpn) currently shows several 2026 CVEs open for Bullseye and fixed for Trixie.

## Recommended tracks

### Track A — conservative, supported, and easiest to maintain

1. Base on `debian:trixie-20260713-slim`.
2. Use Trixie's Boost 1.83, CMake 3.31.6, and Ninja 1.12.1 instead of downloading “latest” build tools.
3. Source-build and pin libtorrent 1.2.20 to preserve the existing `latest` image's 1.x semantics documented in [`README:40-46`](../../README.md#L40-L46).
4. Source-build and pin qBittorrent 5.2.3 from its signed official release tarball.
5. Use Trixie stable OpenVPN 2.6.14 and WireGuard tools 1.0.20210914 initially.

This track removes the broken Boost selector, Ninja ambiguity, CMake architecture hard-code, Bullseye/unstable package mixing, and most “latest at build time” variability.

### Track B — latest build tools, same application behavior

Use Track A's Debian/qBittorrent/libtorrent/VPN choices, but source-install pinned Boost 1.91.0, Ninja 1.13.2, and CMake 4.4.1 with published SHA-256 verification and explicit amd64/arm64 asset mapping. These versions are current, but they provide no application feature required by qBittorrent 5.2.3 over Trixie's adequate build tools.

### Track C — libtorrent 2

Use this track only if intentionally changing the image variant from its documented libtorrent 1.x behavior. Debian's libtorrent 2.0.11 is the simplest option and passed the arm64 full-build test; source-built 2.0.13 is the newest supported 2.0.x release. qBittorrent's own 5.2.3 release builds use either a post-1.2.20 snapshot or a post-2.0.13 snapshot ([official release news](https://www.qbittorrent.org/news#tue-jul-07th-2026---qbittorrent-v5.2.3-release)). Libtorrent 2.1.0 is current upstream but outside qBittorrent 5.2.3's supported 2.0.x range and includes API changes plus default WebTorrent support that widens the attack surface ([official v2.1.0 notes](https://github.com/arvidn/libtorrent/releases/tag/v2.1.0)).

### Backports are a later optimization

OpenVPN 2.7.5 and WireGuard tools 1.0.20250521 are available from Trixie backports. They should be evaluated only after the stable Trixie image passes representative provider configurations. Stable OpenVPN 2.6.14 is not missing the July 2026 security fixes: Debian backported them from 2.6.21 into `2.6.14-1+deb13u3`.

## Required package and Dockerfile implications

- Replace Qt 5 build packages at [`Dockerfile:136-138`](../../Dockerfile#L136-L138) with Qt 6 development packages. The successful build set was `qt6-base-dev qt6-base-private-dev qt6-tools-dev`; `qt6-tools-dev` supplies the needed LinguistTools component in the tested setup.
- Replace Qt 5 runtime packages at [`Dockerfile:178-180`](../../Dockerfile#L178-L180) with `libqt6network6`, `libqt6xml6`, `libqt6sql6`, and the runtime-required SQLite driver `libqt6sql6-sqlite`; Qt Core is pulled transitively. Trixie package versions are 6.8.2+dfsg-9+deb13u2 ([Network](https://packages.debian.org/trixie/libqt6network6), [XML](https://packages.debian.org/trixie/libqt6xml6), [SQL](https://packages.debian.org/trixie/libqt6sql6), [SQLite driver](https://packages.debian.org/trixie/libqt6sql6-sqlite)).
- Replace removed `libssl1.1` at [`Dockerfile:181`](../../Dockerfile#L181) with Trixie's `libssl3t64` 3.5.6 ([package](https://packages.debian.org/trixie/libssl3t64)).
- Remove or change the stale `-DCMAKE_CXX_STANDARD=17` at [`Dockerfile:144`](../../Dockerfile#L144); qBittorrent declares C++20. Its target feature may raise the standard itself, but retaining 17 is misleading and leaves compiler behavior less explicit.
- Remove the `unstable` WireGuard repository at [`Dockerfile:168-170`](../../Dockerfile#L168-L170). Trixie stable already carries WireGuard tools.
- Change the hard-coded `bullseye non-free` source at [`Dockerfile:196`](../../Dockerfile#L196) to the Trixie non-free component if `unrar` remains, so the image does not mix Debian releases.
- Prefer `7zip` over the transitional `p7zip-full` package.
- Add `iproute2` explicitly to the runtime packages. With `--no-install-recommends`, the tested Trixie package set did not install it, so `ip` was absent; [`qbittorrent/iptables.sh:48-90`](../../qbittorrent/iptables.sh#L48-L90) and `wg-quick` cannot work without it. [Trixie iproute2 package](https://packages.debian.org/trixie/iproute2).
- Replace API/RSS “latest” discovery with version arguments and checksum verification. The current repeated `apt upgrade` calls also make every rebuild mutable even when the base tag is unchanged.
- If multi-architecture images are intended, all downloaded assets need `TARGETARCH` mapping. Today CMake is amd64-only and Ninja's broad match installs the ARM64 binary first; the current source is not a working multi-arch build.
- Adapt the routing-table setup before trying to start the Trixie image. [`qbittorrent/iptables.sh:87-88`](../../qbittorrent/iptables.sh#L87-L88) appends to `/etc/iproute2/rt_tables`, but Trixie's `iproute2` installs that file at `/usr/share/iproute2/rt_tables`; the current append fails because `/etc/iproute2` is absent. Compare the official [Bullseye file list](https://packages.debian.org/bullseye/amd64/iproute2/filelist) with the [Trixie file list](https://packages.debian.org/trixie/amd64/iproute2/filelist). Use a supported local override/drop-in or numeric routing table consistently, then re-prove the marked WebUI route and killswitch behavior.

## Upgrade and runtime risks

### qBittorrent profile migration and rollback

qBittorrent 5.2.3 migrates settings in the mounted profile, including proxy profiles, share-limit action, and “add paused” to “add stopped,” then records migration version 8. The relevant upstream code is [upgrade.cpp lines 388-415](https://github.com/qbittorrent/qBittorrent/blob/release-5.2.3/src/app/upgrade.cpp#L388-L415) and [456-544](https://github.com/qbittorrent/qBittorrent/blob/release-5.2.3/src/app/upgrade.cpp#L456-L544). Back up `/config/qBittorrent` before the first 5.2.3 start; rolling back the binary should also restore that backup.

Version 5 changed UI/API terminology from Resume/Pause to Start/Stop ([changelog](https://github.com/qbittorrent/qBittorrent/blob/release-5.2.3/Changelog#L415)). WebAPI torrent states now include `stoppedUP` and `stoppedDL` ([serializer](https://github.com/qbittorrent/qBittorrent/blob/release-5.2.3/src/webui/api/serialize/serialize_torrent.cpp#L44-L75)). Test any external automation that parses old paused states or invokes old action names.

### WebUI credentials

[`qbittorrent/qBittorrent.conf:9-12`](../../qbittorrent/qBittorrent.conf#L9-L12) sets username `admin` but no password, while [`README:89-95`](../../README.md#L89-L95) still promises `adminadmin`. Since qBittorrent 4.6.1, default credentials are rejected and a random temporary password is emitted when no custom password exists ([official notice](https://www.qbittorrent.org/news#mon-nov-20th-2023---qbittorrent-v4.6.1-release)). This image redirects qBittorrent stdout/stderr to `/config/qBittorrent/data/logs/qbittorrent.log` at [`qbittorrent/qbittorrent.init:28-33`](../../qbittorrent/qbittorrent.init#L28-L33), so the password may not appear in `docker logs`. The documentation and first-start flow need to be updated together.

### OpenVPN 2.5 to 2.6 / OpenSSL 3

Provider `.ovpn` files need real connection testing. OpenVPN 2.6 changed its default data-cipher list and only accepts ciphers in `--data-ciphers`; compatibility modes can append an older `--cipher` value. OpenSSL 3 also does not enable Blowfish and other deprecated algorithms by default. Primary sources: OpenVPN's [cipher negotiation documentation](https://github.com/OpenVPN/openvpn/blob/v2.6.14/doc/man-sections/cipher-negotiation.rst#L8-L25) and [2.6 changes](https://github.com/OpenVPN/openvpn/blob/v2.6.14/Changes.rst#L999-L1014). Do not silently enable the OpenSSL legacy provider globally; update old provider profiles or use the narrowest explicit compatibility setting after testing.

### Test boundary

The successful arm64 Trixie/qBittorrent builds prove compilation for both selected libtorrent paths only. Before calling the update complete, build amd64 too, install `iproute2`, fix and verify the Trixie `rt_tables` behavior, start qBittorrent against a disposable copy of a real profile, verify WebUI login and config migration, connect representative OpenVPN and WireGuard profiles, and prove the iptables killswitch by dropping each tunnel. Also inspect `qbittorrent-nox --version` and linked Qt/OpenSSL/libtorrent versions inside the final runtime image.

## Suggested implementation order

1. Pin the Debian base and replace package names/suites.
2. Use distro Boost/CMake/Ninja or explicitly pin the latest-tool track.
3. Pin libtorrent 1.2.20 and qBittorrent 5.2.3 with checksums.
4. Complete compile and runtime smoke tests without a user profile.
5. Back up and test a copy of an existing qBittorrent profile, including temporary-password handling and external WebAPI clients.
6. Test OpenVPN 2.6 and WireGuard stable against real provider configurations.
7. Verify killswitch behavior and only then consider libtorrent 2 or Trixie-backports VPN tools.
