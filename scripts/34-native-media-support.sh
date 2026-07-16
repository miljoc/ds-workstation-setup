#!/usr/bin/env bash
set -euo pipefail

install_if_available() {
  local package="$1"
  if dnf -q list --available "$package" >/dev/null 2>&1 || rpm -q "$package" >/dev/null 2>&1; then
    sudo dnf install -y "$package"
  else
    echo "↷ $package is niet beschikbaar in de ingeschakelde Rocky 10 repositories; overslaan."
  fi
}

# WebM/VP8/VP9/Opus and common codecs for GNOME/GStreamer applications.
for package in \
  gstreamer1-plugins-base \
  gstreamer1-plugins-good \
  gstreamer1-plugins-bad-free \
  gstreamer1-plugins-ugly \
  gstreamer1-plugin-libav \
  ffmpeg
do
  install_if_available "$package"
done

# Loupe + Glycin provide native GNOME image viewing, including WebP where supported.
for package in loupe glycin-loaders libwebp-tools; do
  install_if_available "$package"
done

# glycin-thumbnailer and eog are intentionally not requested: they are absent from
# the current Rocky Linux 10 repositories and Loupe is the supported GNOME viewer.

echo "Native WebM/WebP media support installed."
