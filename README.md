# php-devcontainer

Shared, prebuilt Docker images for Laravel PHP Dev Containers, based on
[`serversideup/php`](https://github.com/serversideup/docker-php) `fpm-nginx-alpine`.

## Tags

`ghcr.io/fer-ri/php-devcontainer:<php>-<target>` for:

- `php`: `7.4`, `8.5`
- `target`: `base`, `dev`, `ci`

Example: `ghcr.io/fer-ri/php-devcontainer:8.5-dev`

What each target contains:

- **base** — `serversideup/php` + PHP extensions `bcmath`, `intl`.
- **dev** — `base` + `git`, `openssh`, `shadow`, and Node.js (copied from a
  `node:*-alpine` image via multi-stage `COPY`). The Node version is matched to
  the PHP base's Alpine release — Node 24 for `8.5` (Alpine 3.23), Node 18 for
  `7.4` (Alpine 3.16) — to avoid `libstdc++` mismatches. Remaps `www-data` to
  your UID/GID at container startup (see below).
- **ci** — `base` with the php-fpm pool set to run as `www-data`.

## Building locally

```bash
docker login ghcr.io
./build.sh
```

`build.sh` builds and pushes every `php` × `target` combination (amd64 only).

CI builds the same matrix on every push to `main` via
`.github/workflows/build.yml` (public package, no local login needed to pull).

## Using in a project

### Dev / CI (no per-project Dockerfile needed)

```yaml
# docker-compose.yml
services:
  app:
    image: ghcr.io/fer-ri/php-devcontainer:8.5-dev
    environment:
      - USER_ID=${USER_ID:-1000}
      - GROUP_ID=${GROUP_ID:-1000}
```

`www-data` is remapped to `USER_ID:GROUP_ID` (default `1000:1000`) at container
startup via `/etc/entrypoint.d/10-fix-uid.sh`, so the devcontainer runs as your
host user with no custom Dockerfile.

### Deploy / production (per-project, 3 lines)

App code is project-specific, so the `deploy` stage stays in each project:

```dockerfile
FROM ghcr.io/fer-ri/php-devcontainer:8.5-base AS deploy
COPY --chown=www-data:www-data . /var/www/html
USER www-data
```
