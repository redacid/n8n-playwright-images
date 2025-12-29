ARG NODE_VERSION=22.21.1

# ==============================================================================
# STAGE 1: Builder for Base Dependencies
# ==============================================================================
FROM node:${NODE_VERSION}-bookworm AS builder

# Install fonts
RUN apt update && apt upgrade -y
    #apt install -y ttf-mscorefonts-installer
#RUN \
#  apk --no-cache add --virtual .build-deps-fonts msttcorefonts-installer fontconfig && \
#  update-ms-fonts && \
#  fc-cache -f && \
#  apk del .build-deps-fonts && \
#  find /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \;

# Install essential OS dependencies
RUN \
    apt install -y \
        git \
        openssh-client \
        openssl \
        graphicsmagick \
        tini \
        tzdata \
        ca-certificates \
        libc6 \
        jq \
    		mc

# Install full-icu
RUN npm install -g full-icu@1.5.0

RUN rm -rf /tmp/* /root/.npm /root/.cache/node

# ==============================================================================
# STAGE 2: Final Base Runtime Image
# ==============================================================================
FROM node:${NODE_VERSION}-bookworm

COPY --from=builder / /

RUN rm -rf /opt/yarn*
    #&& apk del apk-tools

WORKDIR /home/node
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu
EXPOSE 5678/tcp
