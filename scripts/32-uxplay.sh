#!/usr/bin/env bash
set -euo pipefail

UXPLAY_TAG="${UXPLAY_TAG:-v1.73}"
BUILD_ROOT="$HOME/.cache/doorapi-build"
SOURCE_DIR="$BUILD_ROOT/UxPlay"
SERVICE_DIR="$HOME/.config/systemd/user"

sudo dnf install -y \
  git \
  gcc-c++ \
  cmake \
  make \
  openssl-devel \
  libplist-devel \
  avahi-compat-libdns_sd-devel \
  gstreamer1 \
  gstreamer1-devel \
  gstreamer1-plugins-base \
  gstreamer1-plugins-base-devel \
  gstreamer1-plugins-good \
  gstreamer1-plugins-bad-free \
  gstreamer1-plugin-libav

mkdir -p "$BUILD_ROOT" "$SERVICE_DIR"

if [ ! -d "$SOURCE_DIR/.git" ]; then
  git clone https://github.com/FDH2/UxPlay.git "$SOURCE_DIR"
else
  git -C "$SOURCE_DIR" fetch --tags --prune
fi

git -C "$SOURCE_DIR" checkout --force "$UXPLAY_TAG"

cmake -S "$SOURCE_DIR" -B "$SOURCE_DIR/build" -DCMAKE_BUILD_TYPE=Release
cmake --build "$SOURCE_DIR/build" --parallel "$(nproc)"
sudo cmake --install "$SOURCE_DIR/build"
sudo ldconfig

if ! /usr/local/bin/uxplay -v | grep -q 'UxPlay version'; then
  echo "ERROR: UxPlay installation failed."
  exit 1
fi

cat > "$SERVICE_DIR/uxplay.service" <<'EOF_SERVICE'
[Unit]
Description=UxPlay AirPlay Receiver
PartOf=graphical-session.target
After=graphical-session.target network-online.target
Wants=network-online.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
Type=simple
ExecStart=/usr/local/bin/uxplay -p -vs gtkwaylandsink
Restart=on-failure
RestartSec=3
Environment=PATH=/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=default.target
EOF_SERVICE

if systemctl is-active --quiet firewalld; then
  sudo firewall-cmd --permanent --add-service=mdns
  sudo firewall-cmd --permanent --add-port=7000-7001/tcp
  sudo firewall-cmd --permanent --add-port=7100/tcp
  sudo firewall-cmd --permanent --add-port=6000-6001/udp
  sudo firewall-cmd --permanent --add-port=7011/udp
  sudo firewall-cmd --reload
else
  echo "WARNING: firewalld is not active; UxPlay firewall rules were not applied."
fi

systemctl --user daemon-reload
systemctl --user enable --now uxplay.service
systemctl --user restart uxplay.service

echo "UxPlay $UXPLAY_TAG installed and started with legacy ports and gtkwaylandsink."
