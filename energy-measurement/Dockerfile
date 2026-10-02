# Release v2.53.0 (67ad42147a7acc2af6074753ebd03d904476118f): same cell and package list as the HEAD campaign.
# Reference cell: .github/workflows/main.yml, job `dockerized`, jobname `debian-11`
# (cell 1 of 45; see the fidelity note for the selection criteria). That cell already
# runs in a container upstream, so this image reproduces an existing containerisation
# rather than introducing one.
#
# Pinned by digest: Debian 11 leaves support on 2026-08-31 and the tag will move.
FROM debian@sha256:99cdf7792e25416bd801861ccd8e2fb27fb527b25e8d9a8704ebc3ead2015675

ENV DEBIAN_FRONTEND=noninteractive

# Package list of the debian-* branch of ci/install-dependencies.sh, with the
# versions resolved on 2026-08-19 by the HEAD campaign. Debian 11 left support on
# 2026-08-31 and deb.debian.org no longer serves its security pool, so the same
# versions are fetched from the snapshot archive of 2026-08-20. Recommends are kept because the upstream script
# does not pass --no-install-recommends. The p4, git-lfs and jgit downloads of that
# script sit in its ubuntu-* branch and do not run for this cell, so they are absent
# here as well.
RUN printf 'deb http://snapshot.debian.org/archive/debian/20260820T000000Z bullseye main\ndeb http://snapshot.debian.org/archive/debian-security/20260820T000000Z bullseye-security main\ndeb http://snapshot.debian.org/archive/debian/20260820T000000Z bullseye-updates main\n' > /etc/apt/sources.list \
    && apt-get -q -o Acquire::Check-Valid-Until=false update \
    && apt-get -q -y -o Acquire::Check-Valid-Until=false install \
        locales-all=2.31-13+deb11u14 \
        apache2=2.4.67-1~deb11u3 \
        cvs=2:1.12.13+real-28 \
        cvsps=2.1-8 \
        git=1:2.30.2-1+deb11u5 \
        gnupg=2.2.27-2+deb11u3 \
        libsvn-perl=1.14.1-3+deb11u2 \
        subversion=1.14.1-3+deb11u2 \
        make=4.3-4.1 \
        libssl-dev=1.1.1w-0+deb11u8 \
        libcurl4-openssl-dev=7.74.0-1.3+deb11u16 \
        libexpat1-dev=2.2.10-2+deb11u7 \
        wget=1.21-1+deb11u2 \
        sudo=1.9.5p2-3+deb11u4 \
        default-jre=2:1.11-72 \
        tcl=8.6.11+1 \
        tk=8.6.11+1 \
        gettext=0.21-4 \
        zlib1g-dev=1:1.2.11.dfsg-2+deb11u2 \
        perl-modules-5.32=5.32.1-4+deb11u5 \
        liberror-perl=0.17029-1 \
        libauthen-sasl-perl=2.1600-1.1 \
        libemail-valid-perl=1.202-1 \
        libio-pty-perl=1:1.15-2 \
        libio-socket-ssl-perl=2.069-1 \
        libnet-smtp-ssl-perl=1.04-1 \
        libdbd-sqlite3-perl=1.66-1+b1 \
        libcgi-pm-perl=4.51-1 \
        libsecret-1-dev=0.20.4-2 \
        libpcre2-dev=10.36-2+deb11u1 \
        meson=0.56.2-1 \
        ninja-build=1.10.1-1 \
        pkg-config=0.29.2-1 \
        cargo=0.47.0-3+b1 \
        gcc=4:10.2.1-1 \
    && rm -rf /var/lib/apt/lists/*

# The upstream cell runs the suite as a non-root user created by the job
# (`useradd builder`, then `sudo --user=builder`). Running as root suppresses 657
# tests whose prerequisites assume an unprivileged process.
RUN groupadd -g 1001 runner && \
    useradd -u 1001 -g 1001 -m -d /home/runner -s /bin/bash runner

# CUSTOM_PATH is prepended to PATH by ci/lib.sh; it stays empty for this cell.
RUN mkdir -p /custom /timing /work && chmod 777 /timing /work

# Pristine checkout. run_pipeline.sh copies it into the shared build volume before
# the measured window, so the build stage always starts from an unbuilt tree.
COPY . /project
RUN chown -R runner:runner /project

USER runner
WORKDIR /work/git
