# Restoration and Customization Scripts — Jellyfin → Viveo

This repository contains personal scripts to restore and modify a standard Jellyfin installation to match the look and configuration used on my Viveo platform. It is a toolbox for applying customizations, restorations, and optimizations.

## Repository contents

- `restoreCustom/` — restoration and customization scripts (main script: `restore-viveo-customizations.sh`).
- `optimizationGIF/` — files and HTML pages for GIF optimization and asset checks.

## Purpose

Adapt a vanilla Jellyfin instance into a configuration and appearance consistent with the Viveo platform (themes, configuration files, optimized assets, and other adjustments).

## Requirements

- A working Jellyfin installation.
- Back up important data (configs, databases, media) before applying changes.

## Quick start

1. Review the script(s) and update any paths or variables to match your installation.
2. Make the main script executable:

```bash
chmod +x restoreCustom/restore-viveo-customizations.sh
```

3. Run the script

```bash
sudo ./restoreCustom/restore-viveo-customizations.sh
```

Note: Inspect the script before running and test on a development instance if possible.

## Key files & scripts

- `restoreCustom/restore-viveo-customizations.sh` — applies Viveo customizations.
- `optimizationGIF/` — HTML pages and resources to prepare or verify GIF optimizations.

## Viveo base site

The Viveo platform reference site is: https://viveo.borrelly-betta.ts.net/

## Contributing

Add scripts or variants in clearly named subfolders, open an issue to propose changes, or create a branch and submit a pull request. Document each script with its purpose and prerequisites.


## Support

Open an issue in this repository for questions, suggestions, or problems related to the scripts.

---

Main restoration script: `restoreCustom/restore-viveo-customizations.sh` — review before running.
