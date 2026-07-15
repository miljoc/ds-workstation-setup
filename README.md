# DS Dev Machien

Bootstrap for a Rocky Linux DoorAPI development workstation.

## Install

```bash
./install.sh
```

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
