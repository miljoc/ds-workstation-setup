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
