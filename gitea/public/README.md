# Custom AtomicQMS Logos

This directory contains custom logo files that override Gitea's default branding.

## Logo Files

Located in `public/assets/img/`:

- **`logo.svg`** - Mini logo (replaces the Gitea teacup icon)
  - Used in the header, navigation, and as the site icon
  - Source: `atomicqms-mini-logo.svg`

- **`logo-full.svg`** - Full logo
  - Available for larger branding areas if needed
  - Source: `atomicqms-full-logo.svg`

## How It Works

The docker-compose configuration mounts `./gitea:/data`, which means:

- `gitea/public/assets/img/logo.svg` → `/data/public/assets/img/logo.svg` in container
- Gitea's `GITEA_CUSTOM` path is `/data/gitea` (the default)
- Custom assets in `/data/public/` override embedded assets

This allows the stock `gitea/gitea:latest` Docker image to use custom branding without modification.

## Updating Logos

To change logos in the future:

1. Replace the SVG files:
   ```bash
   cp /path/to/new-mini-logo.svg gitea/public/assets/img/logo.svg
   cp /path/to/new-full-logo.svg gitea/public/assets/img/logo-full.svg
   ```

2. Restart the container:
   ```bash
   docker compose restart
   ```

3. Hard refresh your browser (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows/Linux)

## File Requirements

- **Format**: SVG (Scalable Vector Graphics)
- **Naming**: Must be named `logo.svg` to override the default
- **Permissions**: Readable by the container's git user (UID 1000)

## Additional Customization

You can add other custom public assets in this directory:

- `public/robots.txt` - Custom robots.txt
- `public/.well-known/` - Well-known URIs
- `public/assets/css/` - Custom stylesheets
- `public/assets/js/` - Custom JavaScript
- `public/assets/img/favicon.svg` - Custom favicon

All files in `public/` are served at the root path in Gitea.
