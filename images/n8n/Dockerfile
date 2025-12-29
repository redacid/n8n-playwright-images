ARG NODE_VERSION=22.21.1
ARG N8N_VERSION=snapshot
ARG N8N_BASE_IMAGE=snapshot

# ==============================================================================
# STAGE 1: System Dependencies & Base Setup
# ==============================================================================
#FROM n8nio/base:${NODE_VERSION} AS system-deps
FROM ${N8N_BASE_IMAGE} AS system-deps

# ==============================================================================
# STAGE 2: Final Runtime Image
# ==============================================================================
FROM system-deps AS runtime

ARG N8N_VERSION
ARG N8N_RELEASE_TYPE=dev
ENV NODE_ENV=production
ENV N8N_RELEASE_TYPE=${N8N_RELEASE_TYPE}
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu
ENV SHELL=/bin/sh

WORKDIR /home/node

COPY ./compiled /usr/local/lib/node_modules/n8n
COPY docker/images/n8n/docker-entrypoint.sh /

# This version of npm has the fix for glob
RUN npm install -g npm@11.6.4

RUN cd /usr/local/lib/node_modules/n8n && \
		npm rebuild sqlite3 && \
		ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n && \
    mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node

RUN cd /usr/local/lib/node_modules/n8n/node_modules/pdfjs-dist && npm install @napi-rs/canvas

RUN npx playwright install-deps

RUN apt clean && apt autoremove

USER node
RUN npx playwright install
RUN ls -la /home/node/.cache/ms-playwright/chromium-1200/
RUN for dir in /home/node/.cache/ms-playwright/chromium-*/; do \
        if [ -d "${dir}chrome-linux64" ] && [ ! -e "${dir}chrome-linux" ]; then \
            ln -s chrome-linux64 "${dir}chrome-linux"; \
            echo "Created symlink: ${dir}chrome-linux -> chrome-linux64"; \
        fi \
    done

EXPOSE 5678/tcp
USER node
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]

LABEL org.opencontainers.image.title="n8n" \
      org.opencontainers.image.description="Workflow Automation Tool" \
      org.opencontainers.image.source="https://github.com/n8n-io/n8n" \
      org.opencontainers.image.url="https://n8n.io" \
      org.opencontainers.image.version=${N8N_VERSION}
