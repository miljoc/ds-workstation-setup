#!/usr/bin/env bash
set -euo pipefail

echo "=== Updating system and installing base + dev packages ==="

sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --set-enabled crb || true
sudo dnf update -y

sudo dnf install -y \
    git curl wget vim nano jq make gcc gcc-c++ autoconf automake perl \
    openssl-devel ncurses-devel libxslt-devel \
    tar unzip zip cmake clang pkgconf-pkg-config \
    podman cockpit cockpit-podman firewalld \
    flatpak gnome-extensions-app \
    wireguard-tools \
    nodejs npm \
    mesa-demos mesa-vulkan-drivers vulkan-loader vulkan-tools \
    glib2-devel gtk4 gtk4-devel \
    cairo cairo-devel pango pango-devel graphene-devel \
    poppler-glib poppler-glib-devel \
    protobuf protobuf-devel protobuf-compiler \
    rust cargo \
    meson ninja-build \
    wayland-devel wayland-protocols-devel \
    gobject-introspection-devel \
    gstreamer1-devel \
    gstreamer1-plugins-base \
    gstreamer1-plugins-base-devel \
    gstreamer1-plugins-base-tools \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-ugly \
    gstreamer1-libav \
    ffmpeg \
    vala vala-devel libvala-devel \
    golang \
    bash-completion fzf fd-find ripgrep bat

sudo dnf install -y \
    gstreamer1-plugins-bad-freeworld \
    || true

sudo systemctl enable --now cockpit.socket
sudo systemctl enable --now firewalld
sudo usermod -aG render,video,wheel "$USER" || true

echo "✅ Base system setup completed!"
