FROM ubuntu:24.04

ARG GID=1000
ARG UID=1000

RUN apt-get update \
    && apt-get install -y \
         openssh-client \
         rsync \
         curl \
    && rm -rf /var/lib/apt/lists/*

RUN (addgroup --gid $GID node || groupmod -n node $(getent group $GID | cut -d: -f1)) \
    && (adduser --gid $GID --uid $UID --disabled-password --gecos "" node || usermod -l node -g $GID -d /home/node -m $(getent passwd $UID | cut -d: -f1))

COPY --chown=node:node run.sh /home/node/run.sh
RUN chmod +x /home/node/run.sh

VOLUME /out
VOLUME /home/node/node.tar.xz

# Note: SSH authentication uses host's SSH agent (mount $SSH_AUTH_SOCK)
# or SSH keys from host's ~/.ssh (mount as volume)

USER node

ENTRYPOINT [ "/home/node/run.sh" ]
