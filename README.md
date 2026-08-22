# Unofficial Manager.io Server container for easy setup of latest free manager.io Accounting Software to run in a container

An unofficial community container for [Manager Server](https://www.manager.io/server-edition), built from the official Linux release and packaged with headless Chromium so Manager's PDF and email-attachment features work out of the box.

This project is not affiliated with, sponsored by, or endorsed by NGSoftware Pty Ltd or Manager. Manager names and trademarks belong to their respective owner.

## Why this image exists

Manager publishes official Linux binaries but does not currently publish an official container image. A minimal runtime container can run the accounting server, but Manager's internal PDF generator also needs a compatible headless browser and its system libraries. This image combines:

- the version-pinned official Manager Server Linux binary;
- Microsoft's official Playwright runtime with Chromium;
- a non-root runtime user (`10001:10001`);
- `amd64` and `arm64` images; and
- Manager's upstream licence and third-party notices inside `/licenses/manager-server`.

No third-party Manager binary is used.

## Quick start

Replace `OWNER/REPOSITORY` with the GitHub owner and repository name where the image is published. Then create the data directory and make it writable by the container user:

```bash
mkdir -p ./data
sudo chown -R 10001:10001 ./data
```

Use this Compose configuration for host-local access through a reverse proxy or Tailscale Serve:

```yaml
services:
  manager:
    image: ghcr.io/OWNER/REPOSITORY:latest
    container_name: manager-server
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - ./data:/data
    environment:
      TZ: Etc/UTC
    restart: unless-stopped
    stop_grace_period: 30s
    init: true
    shm_size: "256mb"
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```

Start it:

```bash
docker compose up -d
```

Manager listens on port `8080` inside the container and stores all application data in `/data`.

### LAN access

The example deliberately binds to `127.0.0.1`, so other devices cannot connect directly. To allow access from the local network, change the port mapping to:

```yaml
ports:
  - "8080:8080"
```

Then open `http://SERVER-IP:8080`.

Do not forward port 8080 directly from an internet router. Use an authenticated HTTPS reverse proxy, Tailscale Serve, Cloudflare Access, or an equivalent secure access layer.

## HTTPS is required for PDF and Email buttons

Current Manager Server versions use the browser Web Crypto API while preparing PDFs. Browsers only expose that API in a secure context. Manager itself can be used at an HTTP LAN address, but its **PDF** and **Email** buttons may appear to do nothing.

Use an HTTPS address, such as a Tailscale Serve hostname or an HTTPS reverse proxy. For example:

```bash
sudo tailscale serve --bg http://127.0.0.1:8080
```

## Versioning and updates

The publishing workflow checks Manager's official GitHub releases daily. When a new release appears, it builds and publishes:

- `ghcr.io/OWNER/REPOSITORY:VERSION`
- `ghcr.io/OWNER/REPOSITORY:latest`

The moving `latest` tag does **not** update an already-running container. To update deliberately:

```bash
docker compose pull manager
docker compose up -d manager
```

Back up `/data` before updating. Accounting-data formats can be migrated by newer application versions, so fully unattended container updates are not recommended.

For a controlled production deployment, pin a version:

```yaml
image: ghcr.io/OWNER/REPOSITORY:26.8.14
```

Then change the tag only after confirming that the backup succeeded and reviewing the upstream release.

## Backups

Back up the entire mounted `/data` directory. It contains Manager users, settings, authentication configuration, attachments, and business files. Individual businesses can also be backed up from within Manager.

Do not rely on the container layer as a backup. Containers are disposable; `/data` is the persistent state.

## GitHub Container Registry setup

1. Create a public GitHub repository, for example `manager-server-container`.
2. Add these files and push the default branch.
3. Open **Actions → Publish container → Run workflow**.
4. Leave the Manager version blank to build the latest official release.
5. After the first publication, open the package settings and make the package public.

The workflow uses the repository's standard `GITHUB_TOKEN`; no personal access token is required.

## Build locally

```bash
docker buildx build \
  --build-arg MANAGER_VERSION=26.8.14 \
  --platform linux/amd64 \
  --tag manager-server:26.8.14 \
  --load .
```

## Verification

Confirm the server and bundled browser:

```bash
docker logs manager-server
docker exec manager-server chromium --version
```

Then verify that Manager can create a PDF through an HTTPS connection before relying on emailed invoices.

## Licences

The container packaging in this repository is available under the MIT License.

Manager Server is redistributed under the [Functional Source License 1.1 with an Apache 2.0 Future License](https://github.com/managerhq/ManagerServer/blob/main/LICENSE.md). Its licence permits redistribution for permitted, non-competing purposes provided the licence or a link is included and copyright notices are preserved. The exact upstream licence and third-party notices for the packaged version are included in the image under `/licenses/manager-server`.

Microsoft Playwright, Chromium, the base operating system and their components retain their own licences. Users are responsible for complying with Manager Server's licence and any product licensing requirements applying to their use.

## Support

For Manager accounting questions, releases and product issues, use the [official Manager resources](https://www.manager.io/guides). For issues specific to this container packaging, open an issue in this repository.
