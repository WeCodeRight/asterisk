FROM ubuntu:16.04

LABEL maintainer="Mason Chase <mc@wecoderight.com>"

ENV ASTERISK_VERSION 11.25.3
ENV ASTERISK_USER asterisk

RUN useradd --system $ASTERISK_USER

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
    autoconf binutils-dev build-essential ca-certificates file curl libcurl3 libcurl4-openssl-dev libedit-dev libgsm1-dev  \
    libjansson-dev libogg-dev libpopt-dev libresample1-dev libspandsp-dev libspeex-dev libspeexdsp-dev libsqlite3-dev  \
    libsrtp0-dev libssl-dev libsox-dev libvorbis-dev libxml2-dev mysql-client ncurses-dev ncurses-bin \
    libmysqlclient-dev libmysqld-dev libxslt1-dev portaudio19-dev subversion unixodbc unixodbc-bin unixodbc-dev \
    odbcinst uuid uuid-dev xmlstarlet git automake libtool pkg-config && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/src/asterisk

# Download and install CMAKE
RUN mkdir -p /usr/src/cmake
WORKDIR /usr/src/cmake
RUN curl -LO https://github.com/Kitware/CMake/releases/download/v3.31.5/cmake-3.31.5-linux-aarch64.sh
RUN chmod +x cmake-3.31.5-linux-aarch64.sh
RUN mkdir -p /opt/cmake
RUN sh cmake-3.31.5-linux-aarch64.sh --prefix=/opt/cmake --skip-license
RUN echo 'export PATH=/opt/cmake/bin:$PATH' >> ~/.bashrc

# Compile and install BCG729 library
RUN git clone https://github.com/BelledonneCommunications/bcg729.git /usr/src/bcg729
WORKDIR /usr/src/bcg729
RUN mkdir m4
RUN /opt/cmake/bin/cmake . \
    -DCMAKE_INSTALL_PREFIX="/usr/local" \
    -DENABLE_UNIT_TESTS=no \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_PREFIX_PATH="/usr/local;/usr;"
RUN make
RUN make install

# Compile and install Asterisk
WORKDIR /usr/src/asterisk
RUN ["/bin/bash", "-c", "set -o pipefail && \
    curl -L https://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz | \
    tar --strip-components 1 -xz"]

RUN contrib/scripts/get_mp3_source.sh
RUN ./configure  --with-resample

RUN make -j 16 menuselect.makeopts
RUN menuselect/menuselect --disable BUILD_NATIVE \
    --enable BETTER_BACKTRACES \
    --enable format_mp3 \
    --enable app_mysql \
    --enable res_config_mysql \
    --enable cdr_mysql \
    --enable app_saycountpl \
    --enable app_skel \
    --enable app_fax \
    --enable app_ivrdemo \
    --enable app_saycounted \
    --enable app_readfile \
    --enable app_setcallerid \
    --enable res_pktccops \
    --enable res_fax  \
    --enable res_fax_spandsp  \
    --enable G711_NEW_ALGORITHM  \
    --enable G711_REDUCED_BRANCHING  \
    --enable ODBC_STORAGE  \
    --enable CORE-SOUNDS-EN-WAV  \
    --enable CORE-SOUNDS-EN-ULAW  \
    --enable CORE-SOUNDS-EN-ALAW  \
    --enable CORE-SOUNDS-EN-G729  \
    --enable CORE-SOUNDS-EN-G722  \
    --enable MOH-OPSOUND-ULAW  \
    --enable MOH-OPSOUND-ALAW  \
    --enable MOH-OPSOUND-GSM  \
    --enable MOH-OPSOUND-G729  \
    --enable MOH-OPSOUND-G722  \
    --enable res_chan_stats  \
    --enable app_statsd  \
    --enable res_endpoint_stats  \
    --enable res_ari_mailboxes \
    menuselect.makeopts
RUN make -j 16 all
RUN make -j 16 install
RUN make -j 16 samples

# Asterisk G729 Codec
RUN git clone https://github.com/arkadijs/asterisk-g72x.git /usr/src/asterisk-g72x
WORKDIR /usr/src/asterisk-g72x
RUN ./autogen.sh
RUN ./configure --with-asterisk100 --with-bcg729 --prefix /usr/src/asterisk
RUN make && make install
RUN mv /usr/src/asterisk/lib/asterisk/modules/codec_g729.so /usr/lib/asterisk/modules/codec_g729.so
WORKDIR /usr/lib/asterisk/modules/
RUN chown -R asterisk:asterisk codec_g729.so
RUN chmod +x codec_g729.so

RUN rm -rf /usr/src/asterisk
RUN mkdir -p /home/${ASTERISK_USER} && chown -R ${ASTERISK_USER}: /home/${ASTERISK_USER}
RUN mkdir -p /var/spool/asterisk/fax
RUN chown -R ${ASTERISK_USER}: /etc/asterisk /var/*/asterisk /usr/*/asterisk
RUN chmod -R 750 /var/spool/asterisk

COPY ./11/docker-entrypoint.sh /
COPY ./11/docker-entrypoint.d/ /docker-entrypoint.d/
COPY ./11/asterisk-config-files.csv /tmp/

WORKDIR /var/lib/asterisk/agi-bin
EXPOSE 5060/udp 5060/tcp
VOLUME /var/lib/asterisk/sounds /var/lib/asterisk/keys /var/lib/asterisk/phoneprov /var/spool/asterisk /var/log/asterisk
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["asterisk", "-T", "-W", "-U", "asterisk", "-p", "-vvvdddf", "-C", "/etc/asterisk/asterisk.conf"]