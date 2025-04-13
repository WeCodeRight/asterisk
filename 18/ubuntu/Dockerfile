FROM ubuntu:22.04
LABEL maintainer="Mason Chase <mason.chase.public@gmail.com>"
ENV ASTERISK_USER=asterisk
RUN useradd --system asterisk
RUN apt-get update -qq
RUN UBUNTU_PACKAGES=unixodbc
#RUN DEBIAN_PACKAGES=unixodbc-bin
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    autoconf \
    binutils-dev \
    build-essential \
    ca-certificates \
    curl \
    file \
    libcurl4-openssl-dev \
    libedit-dev \
    libgsm1-dev \
    libjansson-dev \
    libogg-dev \
    libpopt-dev \
    libresample1-dev \
    libsox-dev \
    libspandsp-dev \
    libspeex-dev \
    libspeexdsp-dev \
    libopusfile-dev \
    libsqlite3-dev \
    libsrtp2-dev \
    libssl-dev \
    libvorbis-dev \
    libxml2-dev \
    libxslt1-dev \
    default-mysql-client \
    ncurses-bin \
    libncurses-dev \
    odbcinst \
    portaudio19-dev \
    procps \
    subversion \
    unixodbc \
    unixodbc-dev \
    uuid \
    uuid-dev \
    xmlstarlet \
    xsltproc \
    docbook-xsl \
    libjwt-dev \
    python3 \
    net-tools \
    iputils-ping \
    wget \
    tcpdump \
    $DEBIAN_PACKAGES \
    $UBUNTU_PACKAGES

RUN wget http://packages.irontec.com/public.key -q -O /etc/apt/trusted.gpg.d/irontec-debian-repository.asc
RUN apt-get update && apt-get install sngrep build-essential automake libtool cmake pkg-config git doxygen graphviz -y

# Opus
RUN git clone https://gitlab.xiph.org/xiph/opus.git /usr/src/opus
WORKDIR /usr/src/opus
RUN ./autogen.sh
RUN ./configure
RUN make
RUN make install
RUN ldconfig

# G729
RUN git clone https://github.com/BelledonneCommunications/bcg729.git /usr/src/bcg729
WORKDIR /usr/src/bcg729
RUN mkdir m4
RUN cmake . -DCMAKE_INSTALL_PREFIX="/usr/local" -DENABLE_UNIT_TESTS=no -DCMAKE_PREFIX_PATH="/usr/local;/usr;"
# RUN autoupdate && autoconf -i
# RUN ./configure
RUN make
RUN make install

RUN mkdir -p /usr/src/asterisk
WORKDIR /usr/src/asterisk
RUN curl -L http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz | tar --strip-components 1 -xz
#RUN curl -L https://github.com/asterisk/asterisk/releases/download/22.1.0/asterisk-22.1.0.tar.gz | tar --strip-components 1 -xz

RUN git clone https://github.com/wazo-platform/wazo-codec-opus-open-source.git /usr/src/asterisk-opus && \
    cp -rv /usr/src/asterisk-opus/include/asterisk/* /usr/src/asterisk/include/asterisk/ && \
    cp -rv /usr/src/asterisk-opus/codecs/* /usr/src/asterisk/codecs/ && \
    cp -rv /usr/src/asterisk-opus/res/* /usr/src/asterisk/res/

RUN contrib/scripts/get_mp3_source.sh
RUN ./configure \
    --with-resample \
    --with-pjproject-bundled 
RUN make menuselect.makeopts
RUN menuselect/menuselect --disable BUILD_NATIVE menuselect.makeopts
RUN menuselect/menuselect --enable BETTER_BACKTRACES menuselect.makeopts

RUN export
RUN menuselect/menuselect \
    #--enable-category MENUSELECT_MOH \
    #--enable codec_g729a \
    --enable codec_opus \
    --enable app_statsd \
    --enable app_mysql \
    --enable app_fax \
    --enable app_voicemail_odbc \
    --enable chan_sip \
    --enable cdr_pgsql \
    --enable chan_bridge_media \
    --enable chan_rtp \
    --enable app_saycounted \
    --enable res_fax \
    --enable res_fax_spandsp \
    --enable G711_NEW_ALGORITHM \
    --enable G711_REDUCED_BRANCHING \
    --enable CORE-SOUNDS-EN-ULAW \
    --enable res_chan_stats \
    --enable res_endpoint_stats \
    --enable res_ari_mailboxes \
    --enable bridge_native_rtp \
    --enable bridge_simple \
    --enable app_confbridge \
    --enable res_config_mysql \
    --enable res_pjsip \
    --enable res_hep_pjsip \
    --enable res_pjsip_session \
    --enable res_pjsip_registrar \
    --enable chan_pjsip \
    --enable res_stun_monitor \
    --enable codec_resample \
    --disable cdr_sqlite3_custom \
    menuselect.makeopts


RUN make -j 16 all
RUN sed -i -E 's/^SOUNDS_URL:=http:/SOUNDS_URL:=https:/' sounds/Makefile
RUN make install
RUN make -j 8 samples

# G729 Codec
RUN git clone https://github.com/arkadijs/asterisk-g72x.git /usr/src/asterisk-g72x
WORKDIR /usr/src/asterisk-g72x
RUN ./autogen.sh
RUN ./configure --with-bcg729 --prefix /usr/src/asterisk
RUN make && make install
RUN mv /usr/src/asterisk/lib/asterisk/modules/codec_g729.so /usr/lib/asterisk/modules/codec_g729.so
WORKDIR /usr/lib/asterisk/modules/
RUN chown -R asterisk:asterisk codec_g729.so
RUN chmod +x codec_g729.so

# RUN make progdocs
RUN sed -i -E 's/^;(run)(user|group)/\1\2/' /etc/asterisk/asterisk.conf
RUN mkdir -p /var/spool/asterisk/fax

RUN mkdir -p /home/asterisk && chown -R asterisk:asterisk /home/asterisk
# RUN rm -rf /usr/src/asterisk /usr/src/codecs
# RUN rm -rf /var/lib/apt/lists/*
RUN devpackages=`dpkg -l|grep '\-dev'|awk '{print $2}'|xargs`
RUN DEBIAN_FRONTEND=noninteractive apt-get --yes purge \
  autoconf \
  build-essential \
  bzip2 \
  cpp \
  m4 \
  make \
  patch \
  perl \
  perl-modules \
  pkg-config \
  xz-utils \
  subversion \
  ${devpackages}

RUN apt-get update -qq && \
    apt-get install -y \
    net-tools \
    iputils-ping

RUN cd /usr/lib/asterisk/modules
# # Todo: Only if x86
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "x86_64" ]; then \
    curl -s http://asterisk.hosting.lv/bin/codec_g729-ast160-gcc4-glibc-x86_64-core2-sse4.so -o codec_g729.so && \
    curl -s http://asterisk.hosting.lv/bin/codec_g723-ast160-gcc4-glibc-x86_64-core2-sse4.so -o codec_g723.so && \
    chown -R asterisk:asterisk codec_g72*.so && \
    chmod +x codec_g72*.so; \
    ENABLED_CODECS=" --enable codec_opus --enable codec_g729a " \
fi
RUN touch /var/log/asterisk/security && chown asterisk:asterisk /var/log/asterisk/security

EXPOSE 5060/udp 5060/tcp
VOLUME /var/lib/asterisk/keys /var/lib/asterisk/phoneprov /var/spool/asterisk /var/log/asterisk
WORKDIR /var/lib/asterisk/agi-bin

RUN chown -R asterisk:asterisk /var/lib/asterisk 
RUN chown -R asterisk:asterisk /var/spool/asterisk 
RUN chown -R asterisk:asterisk /var/log/asterisk
RUN chown -R asterisk:asterisk /usr/lib/asterisk
RUN chown -R asterisk:asterisk /etc/asterisk
RUN chmod -R 750 /var/spool/asterisk

COPY ./docker-entrypoint.d/ /docker-entrypoint.d/
COPY ./docker-entrypoint.sh /
RUN mkdir -p /home/asterisk/.ssh
RUN chmod +x /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.d/*
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["asterisk", "-T", "-W", "-U", "asterisk", "-p", "-vvvdddf", "-C", "/etc/asterisk/asterisk.conf"]
