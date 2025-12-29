ARG NODE_VERSION=22.21.1

# ==============================================================================
# STAGE 1: Builder for Base Dependencies
# ==============================================================================
FROM node:${NODE_VERSION}-bookworm-slim AS builder

# Install fonts
RUN apt update && apt upgrade -y

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
FROM node:${NODE_VERSION}-bookworm-slim

COPY --from=builder / /

RUN rm -rf /opt/yarn*
RUN apt clean && apt autoremove

WORKDIR /home/node
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu
EXPOSE 5678/tcp
