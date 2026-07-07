#!/usr/bin/env bash
set -euo pipefail

flatpak install -y flathub \
  io.github.vani_tty1.memerist \
  org.kde.glaxnimate \
  org.kde.kdenlive \
  re.sonny.OhMySVG \
  org.blender.Blender \
  com.valvesoftware.Steam || true
