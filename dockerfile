ARG BASE_IMAGE=ubuntu:18.04
FROM ${BASE_IMAGE}

LABEL maintainer="Chris Speers"

ARG DEBIAN_FRONTEND=noninteractive
ARG UNIFI_VERSION
ARG LAST_UPDATE
ENV LAST_UPDATED=${LAST_UPDATE}


ARG PKGURL=https://dl.ui.com/unifi/${UNIFI_VERSION}/unifi_sysvinit_all.deb
ARG REPOURL=https://www.ui.com/downloads/unifi/debian

ADD ${PKGURL} /tmp/unifi.deb

ENV BASEDIR=/usr/lib/unifi \
    DATADIR=/unifi/data \
    LOGDIR=/unifi/log \
    CERTDIR=/unifi/cert \
    RUNDIR=/var/run/unifi \
    ODATADIR=/var/lib/unifi \
    OLOGDIR=/var/log/unifi \
    CERTNAME=cert.pem \
    CERT_PRIVATE_NAME=privkey.pem \
    CERT_IS_CHAIN=false \
    BIND_PRIV=true \
    RUNAS_UID0=true \
    UNIFI_GID=999 \
    UNIFI_UID=999

# Push installing openjdk-8-jre first, so that the unifi package doesn't pull in openjdk-7-jre as a dependency?
# Else uncomment and just go with openjdk-7.
RUN echo "**** install pre-requisites ****" && \
    apt-get update && \
    apt-get install -qy --no-install-recommends \
    apt-utils \
    ca-certificates \
    dirmngr \
    gpg \
    wget \
    apt-transport-https \
    curl \
    dirmngr \
    gpg \
    gpg-agent \
    openjdk-11-jre-headless \
    procps \
    libcap2-bin \
    tzdata

RUN echo '**** setting unifi deb repository ****' && \
    echo "deb ${REPOURL} stable ubiquiti" | tee /etc/apt/sources.list.d/100-ubnt-unifi.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv 06E85760C0A52C50

RUN echo "**** create directories ****" && \
    mkdir -p /usr/unifi \
    /usr/local/unifi/init.d \
    /usr/unifi/init.d \
    /usr/local/docker

#Copy and create the entrypoint/healthcheck scripts
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/
COPY functions /usr/unifi/functions
COPY import_cert /usr/unifi/init.d/

RUN echo "**** create entrypoint ****" && \
    chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/unifi/init.d/import_cert && \
    chmod +x /usr/local/bin/docker-healthcheck.sh

RUN echo "**** user setup ****" && \
    set -ex && \
    mkdir -p /usr/share/man/man1/ && \
    groupadd -r unifi -g $UNIFI_GID && \
    useradd --no-log-init -r -u $UNIFI_UID -g $UNIFI_GID unifi

RUN echo "**** install ****" && \
    apt-get update && apt-get upgrade -yq && \
    apt-get -qy install /tmp/unifi.deb && \
    rm -f /tmp/unifi.deb

RUN echo "**** path creation and linking **** " && \
    chown -R unifi:unifi /usr/lib/unifi && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf ${ODATADIR} ${OLOGDIR} ${BASEDIR}/data ${BASEDIR}/logs && \
    mkdir -p ${DATADIR} ${LOGDIR} && \
    ln -s ${DATADIR} ${BASEDIR}/data && \
    ln -s ${RUNDIR} ${BASEDIR}/run && \
    ln -s ${LOGDIR} ${BASEDIR}/logs && \
    rm -rf ${ODATADIR} ${OLOGDIR} && \
    ln -s ${DATADIR} ${ODATADIR} && \
    ln -s ${LOGDIR} ${OLOGDIR} && \
    mkdir -p /var/cert ${CERTDIR} && \
    ln -s ${CERTDIR} /var/cert/unifi

RUN mkdir -p /unifi && chown unifi:unifi -R /unifi

RUN echo "**** cleanup ****" && apt-get clean

VOLUME ["/unifi", "${RUNDIR}"]

EXPOSE 6789/tcp 
EXPOSE 8080/tcp 
EXPOSE 8443/tcp 
EXPOSE 8880/tcp 
EXPOSE 8843/tcp 
EXPOSE 3478/udp

WORKDIR /unifi

HEALTHCHECK --start-period=5m CMD /usr/local/bin/docker-healthcheck.sh || exit 1

# execute controller using JSVC like original debian package does
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["unifi"]