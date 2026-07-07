#!/usr/bin/env bash
set -euo pipefail

echo "=== Enabling required repositories ==="

sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --set-enabled crb || true

sudo dnf install -y \
  https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm \
  || true

sudo dnf install -y \
  https://download1.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm \
  https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-10.noarch.rpm \
  || true

sudo dnf makecache -y || true

echo "✅ Repositories ready"
