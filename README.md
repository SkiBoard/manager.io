# Manager.io Server Edition Docker Container

An unofficial Docker image for running [Manager.io Server Edition](https://www.manager.io/server-edition) in a container.

The image includes Chromium, enabling Manager’s PDF generation and emailed invoice attachment features without additional configuration.

> This project is not affiliated with, sponsored by, or endorsed by NGSoftware Pty Ltd or Manager.io. Manager names and trademarks belong to their respective owners.

## What you need

- A computer, server, or NAS with Docker installed.
- Docker Compose or a container management application such as Synology Container Manager.
- A folder for storing your Manager.io data.
- An available network port, such as `8080`.

## Step 1: Choose an image version

The image is published to GitHub Container Registry:

```text
ghcr.io/skiboard/manager.io
```

You can use either a specific version:

```yaml
image: ghcr.io/skiboard/manager.io:26.8.21.1
```

Or the latest published version:

```yaml
image: ghcr.io/skiboard/manager.io:latest
```

Using a specific version is recommended if you want to review and control updates. Replace `26.8.21.1` with your preferred published version.

Available versions are listed under:

- [Releases](https://github.com/SkiBoard/manager.io/releases)
- [Container packages](https://github.com/SkiBoard/manager.io/pkgs/container/manager.io)

## Step 2: Create a data folder

Manager.io stores its application data in `/data` inside the container.

Map this location to a folder on your computer or NAS so your data survives container restarts, replacements, and updates.

For example:

```text
/volume1/docker/manager-io/data
```

On a Linux server, you might instead use:

```text
/opt/manager-io/data
```

Or create a `data` folder alongside your Compose file:

```text
./data
```

> Important: Do not delete this folder when updating or recreating the container. It contains your Manager.io application data.

## Step 3: Create your Docker Compose configuration

Create a file named `compose.yaml` containing:

```yaml
services:
  manager:
    image: ghcr.io/skiboard/manager.io:26.8.21.1

    container_name: manager-io

    restart: unless-stopped

    init: true

    shm_size: 256mb

    environment:
      TZ: Australia/Melbourne

    ports:
      - "8080:8080"

    volumes:
      - ./data:/data

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

Adjust the configuration if needed:

- Replace `26.8.21.1` with the version you want to run.
- Change `Australia/Melbourne` to your local time zone.
- Change the first `8080` if another application already uses that port.
- Replace `./data` with an absolute folder path if preferred.

For example, on a Synology NAS:

```yaml
volumes:
  - /volume1/docker/manager-io/data:/data
```

If port `8080` is already in use:

```yaml
ports:
  - "8081:8080"
```

The application would then be available on port `8081`.

### Restricting access to the local machine

The standard configuration:

```yaml
ports:
  - "8080:8080"
```

makes Manager available through the host’s network interfaces.

If you only access Manager through a reverse proxy, Tailscale Serve, or another service running on the same host, you can restrict the published port to localhost:

```yaml
ports:
  - "127.0.0.1:8080:8080"
```

With this configuration, other devices cannot connect directly to the host’s port `8080`.

## Step 4: Start the container

From the directory containing `compose.yaml`, run:

```bash
docker compose up -d
```

Docker will download the image and start Manager.io in the background.

Check that the container is running:

```bash
docker compose ps
```

View the startup logs:

```bash
docker compose logs manager
```

To follow the logs continuously:

```bash
docker compose logs -f manager
```

## Step 5: Open Manager.io

If Docker is running on the same computer you are using:

```text
http://localhost:8080
```

If Docker is running on another computer or NAS:

```text
http://YOUR-SERVER-IP:8080
```

For example:

```text
http://192.168.1.10:8080
```

Replace the address and port with the values relevant to your setup.

If you bound the port to `127.0.0.1`, access Manager through your configured reverse proxy, Tailscale Serve, or another local access method.

## Installing on a Synology NAS

You can deploy the same container through Synology Container Manager.

1. Open **File Station**.

2. Create a folder for the project, for example:

   ```text
   /volume1/docker/manager-io
   ```

3. Inside that folder, create a `data` folder:

   ```text
   /volume1/docker/manager-io/data
   ```

4. Open **Container Manager**.

5. Select **Project**.

6. Click **Create**.

7. Enter a project name, such as:

   ```text
   manager-io
   ```

8. Select the project folder:

   ```text
   /volume1/docker/manager-io
   ```

9. Choose the option to create or enter a Compose configuration.

10. Paste:

    ```yaml
    services:
      manager:
        image: ghcr.io/skiboard/manager.io:26.8.21.1

        container_name: manager-io

        restart: unless-stopped

        init: true

        shm_size: 256mb

        environment:
          TZ: Australia/Melbourne

        ports:
          - "8080:8080"

        volumes:
          - /volume1/docker/manager-io/data:/data

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

11. Save and start the project.

12. Open Manager in your browser:

    ```text
    http://YOUR-NAS-IP:8080
    ```

If you use Tailscale Serve or another reverse proxy on the NAS, consider replacing:

```yaml
ports:
  - "8080:8080"
```

with:

```yaml
ports:
  - "127.0.0.1:8080:8080"
```

## Updating Manager.io

### Recommended: update a pinned version manually

Using a version-specific image gives you control over when updates are installed:

```yaml
image: ghcr.io/skiboard/manager.io:26.8.21.1
```

When a newer version becomes available:

1. Check the [GitHub Releases page](https://github.com/SkiBoard/manager.io/releases).

2. Back up your Manager.io data.

3. Update the version in `compose.yaml`:

   ```yaml
   image: ghcr.io/skiboard/manager.io:NEW-VERSION
   ```

4. Download and start the updated image:

   ```bash
   docker compose pull
   docker compose up -d
   ```

On Synology, edit the project’s Compose configuration and redeploy or restart the project using the updated image version.

Your data remains in the mapped `/data` folder.

> Before upgrading, make sure you have a usable backup. Application updates can change stored data formats, which may make downgrading difficult.

### Alternative: use the latest image

To track the latest published image:

```yaml
image: ghcr.io/skiboard/manager.io:latest
```

To update manually:

```bash
docker compose pull
docker compose up -d
```

If you run an image-update service such as Watchtower, it may automatically update containers using the `latest` tag.

Use a specific version tag if you want to decide when upgrades occur.

## Getting notified about new releases

To receive GitHub notifications when a new image is published:

1. Open the [repository](https://github.com/SkiBoard/manager.io).
2. Click **Watch**.
3. Select **Custom**.
4. Enable **Releases**.
5. Ensure email notifications are enabled in your GitHub account settings.

The repository checks for new official Manager.io releases daily.

When a new version is found and the container image is successfully built, a corresponding GitHub release is created.

No release is created when the version has not changed.

## Troubleshooting

### The container does not start

Check the logs:

```bash
docker compose logs manager
```

Common causes include:

- Port `8080` is already in use.
- The mapped data folder does not exist.
- The container cannot write to the mapped data folder.
- The specified image version does not exist.

### Port 8080 is already in use

Change the host port:

```yaml
ports:
  - "8081:8080"
```

Then open:

```text
http://YOUR-SERVER-IP:8081
```

### The container cannot write to the data folder

The image runs as a non-root user with user and group ID `10001`.

On Linux, you can grant ownership of the data folder to that user:

```bash
sudo chown -R 10001:10001 /path/to/manager-io/data
```

For a Synology installation:

```bash
sudo chown -R 10001:10001 /volume1/docker/manager-io/data
```

Only run this command against the specific Manager.io data directory.

### PDF generation or emailed invoice attachments

Chromium is already included in the image. Manager’s PDF and email-attachment features should work without installing a separate browser.

### Check the running version

The current Manager version appears inside the Manager.io application.

You can also check the configured image:

```bash
docker inspect manager-io --format '{{.Config.Image}}'
```

Example output:

```text
ghcr.io/skiboard/manager.io:26.8.21.1
```

## Security notes

- Avoid exposing Manager.io directly to the public internet without appropriate security controls.
- Prefer a VPN such as Tailscale or a properly configured HTTPS reverse proxy for remote access.
- Use Manager.io authentication and configure multi-factor authentication where available.
- Keep backups of the mapped data folder.
- Review updates before installing them in production environments.

## Licence

The files in this repository are provided under the repository’s MIT licence.

Manager.io Server Edition remains subject to its own licensing terms. Relevant upstream licence and third-party notice files are included under:

```text
licenses/manager-server/
```
