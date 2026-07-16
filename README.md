# DOORSTATION 3.2

██████╗  ██████╗  ██████╗ ██████╗ ███████╗████████╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
██╔══██╗██╔═══██╗██╔═══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
██║  ██║██║   ██║██║   ██║██████╔╝███████╗   ██║   ███████║   ██║   ██║██║   ██║██╔██╗ ██║
██║  ██║██║   ██║██║   ██║██╔══██╗╚════██║   ██║   ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
██████╔╝╚██████╔╝╚██████╔╝██║  ██║███████║   ██║   ██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝

A managed Rocky Linux 10 developer workstation toolkit with an interactive installer, updates, health checks, GNOME extensions, media tools, Walker/Elephant and optional ROCm.

## Install

```bash
./install.sh
```

## Single-command installation

```bash
curl -fsSL https://raw.githubusercontent.com/miljoc/ds-workstation-setup/main/bootstrap/install | bash
```

The bootstrap clones or updates the repository in `~/.local/share/doorstation/source` and launches the interactive installer. Override the Git source with `DOORSTATION_REPO_URL`, `DOORSTATION_BRANCH`, or `DOORSTATION_HOME`.

The global management command is installed as `/usr/local/bin/doorstation`:

```bash
doorstation status
doorstation doctor
doorstation update
doorstation backup
doorstation rollback
doorstation extensions
doorstation logs
doorstation version
```

`duplo.sh` was removed in 3.2. The small `bootstrap/install` file is its maintainable replacement.

## Export current GNOME setup into this wizard

Updates to gnome? use the script to export the new settings

```bash
./scripts/export-current-gnome.sh
```

This updates:

- `gnome/dconf.ini`
- `gnome/enabled-extensions.txt`
- `gnome/extensions/`

Then git commit

## Lock screen video

Place the source video in:

```text
gnome/media/lockscreen.mov
```

The installer copies it to:

```text
~/.local/share/doorapi-dev-machien/media/lockscreen.mov
```

Set Live Lock Screen to that installed path before exporting dconf.

## Icon theme

Tela is installed by `scripts/45-tela-icons.sh` and defaults to:

```text
Tela-pink-dark
```

## Nautilus image tools

The setup installs a native Nautilus context menu under **Afbeelding bewerken** with:

- HEIC/HEIF/AVIF and common image formats to JPG, PNG, or WebP;
- a 2048 px JPG preset;
- rotate left and rotate right actions;
- automatic Nautilus directory refresh after processing.

The extension is installed at:

```text
~/.local/share/nautilus-python/extensions/image_converter.py
```

## UxPlay

UxPlay is built from source and installed in `/usr/local/bin`. The user service starts it with:

```text
uxplay -p -vs gtkwaylandsink
```

`-p` enables the legacy fixed ports. The setup opens mDNS and the required TCP/UDP ports in firewalld.

Override the pinned source tag during installation with, for example:

```bash
UXPLAY_TAG=v1.73 ./install.sh
```

## Screenshot OCR and QR scanning

The setup installs [Shotzy](https://extensions.gnome.org/extension/9707/shotzy/) for GNOME Shell 49/50. It adds OCR, QR scanning, and Google Lens actions to GNOME's built-in screenshot interface.

Installed dependencies include:

- Tesseract OCR with English and Dutch language packs;
- ZBar (`zbarimg`) for QR and barcode recognition;
- Poppler utilities for PDF-related image workflows.

Shotzy is installed as:

```text
~/.local/share/gnome-shell/extensions/shotzy@SamkitJain660.github.io
```

Override its source branch during setup with:

```bash
SHOTZY_REF=main ./install.sh
```

## Nautilus media tools

The setup installs both native Nautilus context-menu extensions:

- `image_converter.py`: JPG, PNG, WebP, resizing, rotation, and Rocky Linux HEIC fallback through `heif-convert`;
- `video_converter.py`: MP4/WebM conversion and audio extraction through FFmpeg, including automatic padding for odd video dimensions.

They are installed under:

```text
~/.local/share/nautilus-python/extensions/
```

## Nautilus new-document templates

The setup installs a structured **New Document** menu for Nautilus. Right-click inside a folder and choose:

```text
New Document
├── General
├── Development
├── DoorAPI
└── Kubernetes
```

Included templates cover empty/text/Markdown files, shell and Python scripts, Elixir/Phoenix files, Docker and Compose files, systemd services, DoorAPI integration and device modules, Ecto schemas/migrations, tests, and common Kubernetes resources.

Templates are installed in the user's XDG Templates directory (normally `~/Templates`). Existing personal templates outside the managed `General`, `Development`, `DoorAPI`, and `Kubernetes` folders are preserved.


## Workstation Tools

The setup installs one consolidated Nautilus extension for image/video conversion, OCR, QR scanning, metadata, SHA-256 and path copying. Developer templates are generated directly by the installer, so no external template directory is required.

## Premium setup wizard

`install.sh` now opens a Whiptail checklist, logs the full installation to
`~/doorstation-setup.log`, keeps the terminal open after success or failure, and
shows the exact failed module when something goes wrong.

Additional GNOME extensions installed from extensions.gnome.org:

- UXPlay Control (8243)
- Medialine (10076)
- GSConnect (1319)
- Custom Command Menu (7024)
- ClipQR (6697)
- ROCm GPU Monitor (9496, only when ROCm is selected)

## Doorstation management CLI

The installer now creates a backup before changing GNOME and installs ``/usr/local/bin/doorstation``.

```bash
doorstation status
doorstation doctor
doorstation extensions
doorstation backup
doorstation rollback
doorstation update
```

GNOME extensions are handled in three groups:

1. **Bundled extensions** from `gnome/extensions/` are copied one UUID at a time and enabled.
2. **Managed EGO extensions** are downloaded by the setup and tracked separately.
3. **Existing user/custom extensions** are never deleted or overwritten by a global sync and are backed up before setup.

A full rollback intentionally restores the exact extension snapshot taken before installation.

## Setupwizard

Interactieve installatie (standaard):

```bash
./install.sh
```

De Whiptail-checklist verschijnt voordat logging wordt gestart. Niet-interactief kan alleen expliciet:

```bash
./install.sh --all
./install.sh --components "core media uxplay gnomeext"
```

Wanneer de omgevingsvariabele `WORKSTATION_COMPONENTS` is gezet, wordt de wizard bewust overgeslagen en toont de installer daarvoor een waarschuwing. Controleer dit met `env | grep WORKSTATION_COMPONENTS` en verwijder hem eventueel met `unset WORKSTATION_COMPONENTS`.

## Walker / Elephant boot reliability fix

This build removes the fragile `ConditionEnvironment=WAYLAND_DISPLAY` check from
Elephant. The Elephant backend does not require a Wayland display and could be
skipped by the systemd user manager before the GNOME session environment was
imported.

Walker now:

- requires `elephant.service`;
- starts only after Elephant responds to `elephant listproviders`;
- retries automatically after login failures;
- is checked for both enabled and active state by the final health check.

## VS Code / Elixir language server policy

Doorstation configures VS Code to use **Expert** as the sole Elixir language server.
During setup it removes Lexical, ElixirLS and the standalone Credo extension to prevent duplicate diagnostics, formatter conflicts and the `command 'Reindex' already exists` crash.

Managed VS Code settings include:

- Expert formatter for Elixir, HEEx and EEx;
- format on save;
- `_build`, `deps`, `.git` and `node_modules` watcher exclusions;
- Todo Tree ripgrep path set to `/usr/bin/rg`;
- login Bash terminal profile (`/usr/bin/bash -l`).

Existing global settings are backed up to `~/.config/Code/User/settings.json.doorstation-backup` before the managed baseline is installed.
