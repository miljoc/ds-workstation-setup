#!/usr/bin/env bash
set -euo pipefail

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

flatpak install -y flathub \
  com.github.tchx84.Flatseal \
  com.rtosta.zapzap \
  com.spotify.Client \
  io.github.shiftey.Desktop \
  com.slack.Slack \
  com.tencent.WeChat \
  org.wireshark.Wireshark \
  io.github.db_mobile.resonance \
  im.riot.Riot || true
