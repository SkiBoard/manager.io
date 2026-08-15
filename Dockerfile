# syntax=docker/dockerfile:1.7

ARG PLAYWRIGHT_IMAGE=mcr.microsoft.com/playwright/dotnet:v1.62.0-noble

FROM alpine:3.22 AS manager-download

ARG MANAGER_VERSION=26.8.14
ARG TARGETARCH

RUN apk add --no-cache ca-certificates curl tar \
    && case "${TARGETARCH}" in \
         amd64) manager_arch="x64" ;; \
         arm64) manager_arch="arm64" ;; \
         *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
       esac \
    && case "${MANAGER_VERSION}" in \
         ""|*[!0-9.]*) echo "Invalid Manager version: ${MANAGER_VERSION}" >&2; exit 1 ;; \
       esac \
    && mkdir -p /opt/manager /licenses/manager-server \
    && curl --fail --location --retry 3 --retry-all-errors \
         "https://github.com/managerhq/ManagerServer/releases/download/${MANAGER_VERSION}/ManagerServer-linux-${manager_arch}.tar.gz" \
         --output /tmp/manager-server.tar.gz \
    && tar -xzf /tmp/manager-server.tar.gz -C /opt/manager \
    && test -x /opt/manager/ManagerServer \
    && curl --fail --location --retry 3 --retry-all-errors \
         "https://raw.githubusercontent.com/managerhq/ManagerServer/${MANAGER_VERSION}/LICENSE.md" \
         --output /licenses/manager-server/LICENSE.md \
    && curl --fail --location --retry 3 --retry-all-errors \
         "https://raw.githubusercontent.com/managerhq/ManagerServer/${MANAGER_VERSION}/THIRD-PARTY-NOTICES.md" \
         --output /licenses/manager-server/THIRD-PARTY-NOTICES.md

FROM ${PLAYWRIGHT_IMAGE}

ARG MANAGER_VERSION=26.8.14
ARG SOURCE_URL=""
ARG VCS_REF=""
ARG CREATED=""

LABEL org.opencontainers.image.title="Unofficial Manager Server container" \
      org.opencontainers.image.description="Community container for Manager Server with headless Chromium PDF support" \
      org.opencontainers.image.version="${MANAGER_VERSION}" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${CREATED}" \
      org.opencontainers.image.licenses="LicenseRef-FSL-1.1-Apache-2.0" \
      io.manager-server.upstream="https://github.com/managerhq/ManagerServer"

USER root

COPY --from=manager-download /opt/manager /opt/manager
COPY --from=manager-download /licenses /licenses
COPY --chmod=0755 docker-entrypoint.sh /usr/local/bin/manager-entrypoint

RUN browser_path="$(find /ms-playwright -type f \
      \( -name chrome -o -name chrome-headless-shell \) \
      -perm /111 | head -n 1)" \
    && test -n "${browser_path}" \
    && ln -sf "${browser_path}" /usr/bin/chromium \
    && groupadd --gid 10001 manager \
    && useradd --uid 10001 --gid 10001 --create-home --home-dir /home/manager manager \
    && mkdir -p /data \
    && chown -R manager:manager /data /home/manager /opt/manager

ENV HOME=/home/manager \
    MANAGER_URLS=http://0.0.0.0:8080 \
    MANAGER_DATA_PATH=/data \
    TZ=UTC \
    DOTNET_GCServer=0 \
    DOTNET_HOSTBUILDER__RELOADCONFIGONCHANGE=false

WORKDIR /opt/manager

VOLUME ["/data"]
EXPOSE 8080

USER 10001:10001

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/8080"]

ENTRYPOINT ["/usr/local/bin/manager-entrypoint"]

