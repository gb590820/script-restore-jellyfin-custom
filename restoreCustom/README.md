# Viveo Jellyfin Customizations

This repository contains a restoration script that reapplies Viveo-specific customizations to a Jellyfin installation after Jellyfin updates.

## What it does

- Updates Jellyfin branding from Jellyfin to Viveo in the web UI.
- Replaces the favicon with a custom Viveo favicon.
- Injects custom scripts into `index.html`.
- Replaces Jellyfin web chunks with Viveo-specific UI behavior.
- Copies branded assets from a local source directory.
- Creates a timestamped backup before applying changes.

## Requirements

- Bash
- Python 3
- A Jellyfin installation with writable web assets
- A local `web_` directory containing the custom source files used by the script

## Expected source files

The script reads custom assets from:

- `web_/favicon.ico`
- `web_/assets/img/banner-dark.png`
- `web_/monitoruserid.js`
- `web_/holidays.js`

## Usage

Run the script after a Jellyfin update:

```bash
sudo bash restore-viveo-customizations.sh
```

The script will:

1. Check that Jellyfin web files exist.
2. Detect whether the Viveo changes already appear to be applied.
3. Create a backup of the current `web` directory.
4. Patch Jellyfin web files and copy the Viveo assets.

## Notes

- The script is designed to be idempotent where possible.
- If the `web_` directory is missing, some custom assets will be skipped.
- Restart Jellyfin after running the script:

```bash
sudo systemctl restart jellyfin
```

## Backup

Each run creates a backup named like:

```text
viveo-backup-YYYYMMDD-HHMMSS
```
