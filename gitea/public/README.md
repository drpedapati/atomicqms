# Custom AtomicQMS Public Assets

This directory provides a place for custom public assets that can be served by Gitea.

**Note**: This is NOT the correct location for custom logos. For custom branding, see the section below.

## Custom Logo Location (IMPORTANT)

Custom logos must be placed in `gitea/gitea/public/assets/img/` (NOT this directory).

**Correct paths**:
- `gitea/gitea/public/assets/img/logo.svg` → `/data/gitea/public/assets/img/logo.svg` in container
- `gitea/gitea/public/assets/img/favicon.svg` → `/data/gitea/public/assets/img/favicon.svg` in container

**Why this location?**
- Docker mounts: `./gitea:/data`
- Gitea's `GITEA_CUSTOM` path: `/data/gitea` (default)
- Custom assets must be in `<GITEA_CUSTOM>/public/` = `/data/gitea/public/`
- This maps to `gitea/gitea/public/` on the host

**Current AtomicQMS Logos**:
- `gitea/gitea/public/assets/img/logo.svg` - AtomicQMS mini logo (atomic structure)
- `gitea/gitea/public/assets/img/logo-full.svg` - AtomicQMS full logo
- `gitea/gitea/public/assets/img/favicon.svg` - Site icon

These files ARE tracked in Git as they are essential to the AtomicQMS brand identity.

## Updating Logos

To change logos in the future:

1. Replace the SVG files:
   ```bash
   cp /path/to/new-mini-logo.svg gitea/gitea/public/assets/img/logo.svg
   cp /path/to/new-mini-logo.svg gitea/gitea/public/assets/img/favicon.svg
   cp /path/to/new-full-logo.svg gitea/gitea/public/assets/img/logo-full.svg
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
