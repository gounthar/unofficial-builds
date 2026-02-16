FROM debian:trixie-slim

RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

ARG NODE_VERSION=24.13.1
ARG NODE_DOWNLOAD_URL=https://github.com/gounthar/unofficial-builds/releases/download
ENV NODE_VERSION=$NODE_VERSION

RUN set -ex \
    && apt-get update && apt-get install -y ca-certificates curl wget xz-utils libatomic1 --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSLO "${NODE_DOWNLOAD_URL}/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-riscv64.tar.xz" \
    && curl -fsSLO "${NODE_DOWNLOAD_URL}/v${NODE_VERSION}/SHASUMS256.txt" \
    && grep " node-v${NODE_VERSION}-linux-riscv64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v${NODE_VERSION}-linux-riscv64.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v${NODE_VERSION}-linux-riscv64.tar.xz" SHASUMS256.txt \
    && find /usr/local/include/node/openssl/archs -mindepth 1 -maxdepth 1 ! -name "linux-riscv64" -exec rm -rf {} \; \
    && apt-mark auto '.*' > /dev/null \
    && find /usr/local -type f -executable -exec ldd '{}' ';' \
      | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
      | sort -u \
      | xargs -r dpkg-query --search \
      | cut -d: -f1 \
      | sort -u \
      | xargs -r apt-mark manual \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    && node --version \
    && npm --version \
    && rm -rf /tmp/*

ENV YARN_VERSION=1.22.22

RUN set -ex \
  && savedAptMark="$(apt-mark showmanual)" \
  && apt-get update && apt-get install -y ca-certificates curl wget gnupg dirmngr --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && export GNUPGHOME="$(mktemp -d)" \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    { gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" && gpg --batch --fingerprint "$key"; } || \
    { gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" && gpg --batch --fingerprint "$key"; } ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && gpgconf --kill all \
  && rm -rf "$GNUPGHOME" \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && apt-mark auto '.*' > /dev/null \
  && { [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; } \
  && find /usr/local -type f -executable -exec ldd '{}' ';' \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  && yarn --version \
  && rm -rf /tmp/*

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

CMD [ "node" ]
