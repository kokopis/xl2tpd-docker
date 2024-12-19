FROM amazonlinux:2023 AS build
# upgrade before building anything
RUN ["dnf", "update"]
RUN ["dnf", "upgrade", "-y"]

# first clone xl2tpd and build it since AL2023 doesn't provide it
WORKDIR /src
RUN ["dnf", "install", "-y", "rpm-build", "git", "gcc", "libpcap-devel-1.10.1-1.amzn2023.0.2.aarch64"]
RUN ["git", "clone", "-b", "v1.3.18", "https://github.com/xelerance/xl2tpd.git", "xl2tpd"]

WORKDIR /src/xl2tpd
RUN ["make"]
RUN ["make", "install"]

FROM amazonlinux:2023 AS run
# install libpcap
RUN ["dnf", "install", "-y", "libpcap-1.10.1-1.amzn2023.0.2.aarch64"]

# upgrade before running anything on the internet
RUN ["dnf", "update"]
RUN ["dnf", "upgrade", "--exclude=libpcap", "-y"]

# install xl2tpd artifacts
COPY --from=build --chown=root:root --chmod=0755 /usr/local/sbin/xl2tpd         /usr/local/sbin/xl2tpd
COPY --from=build --chown=root:root --chmod=0755 /usr/local/bin/pfc             /usr/local/bin/pfc
COPY --from=build --chown=root:root --chmod=0755 /usr/local/sbin/xl2tpd-control /usr/local/sbin/xl2tpd-control

CMD ["xl2tpd", "-v"]
