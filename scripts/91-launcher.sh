#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.local/share/mise/shims:/usr/local/bin:$PATH"
if [ -x "$HOME/.local/bin/mise" ]; then
  eval "$($HOME/.local/bin/mise activate bash)"
fi
export RUSTUP_TOOLCHAIN=stable

BUILD_DIR="$HOME/.cache/doorapi-build"
WALKER_DIR="$BUILD_DIR/walker"
ELEPHANT_DIR="$BUILD_DIR/elephant"
LOCAL_BIN="$HOME/.local/bin"
PROVIDER_DIR="$HOME/.config/elephant/providers"

mkdir -p "$BUILD_DIR" "$LOCAL_BIN" "$PROVIDER_DIR" "$HOME/.config/walker" "$HOME/.config/systemd/user"

echo "=== Walker + Elephant installatie (Rocky Linux 10) ==="

sudo dnf install -y \
  git gcc gcc-c++ make clang pkgconf-pkg-config \
  gtk4 gtk4-devel \
  cairo cairo-devel \
  poppler-glib poppler-glib-devel \
  protobuf protobuf-devel protobuf-compiler \
  glib2-devel pango-devel gdk-pixbuf2-devel \
  golang \
  meson ninja-build vala vala-devel libvala-devel \
  wayland-devel wayland-protocols-devel \
  gobject-introspection-devel

if ! pkg-config --exists gtk4-layer-shell-0; then
  echo "→ Building gtk4-layer-shell..."
  GTKLS_DIR="$BUILD_DIR/gtk4-layer-shell"
  if [ ! -d "$GTKLS_DIR/.git" ]; then
    git clone https://github.com/wmww/gtk4-layer-shell.git "$GTKLS_DIR"
  else
    git -C "$GTKLS_DIR" pull --ff-only
  fi
  cd "$GTKLS_DIR"
  rm -rf build
  meson setup build --prefix=/usr
  ninja -C build
  sudo ninja -C build install
  sudo ldconfig
fi

if ! pkg-config --exists gtk4-layer-shell-0; then
  echo "ERROR: gtk4-layer-shell-0.pc still missing. Cannot build Walker."
  exit 1
fi

echo "→ Building Walker..."
if [ ! -d "$WALKER_DIR/.git" ]; then
  git clone https://github.com/abenz1267/walker.git "$WALKER_DIR"
else
  git -C "$WALKER_DIR" pull --ff-only
fi
cd "$WALKER_DIR"
cargo build --release

WALKER_BIN="$(find target/release -maxdepth 1 -type f -executable -name 'walker' | head -n 1)"
if [ -z "$WALKER_BIN" ]; then
  echo "ERROR: Walker binary not found after build."
  exit 1
fi
cp "$WALKER_BIN" "$LOCAL_BIN/walker"
chmod +x "$LOCAL_BIN/walker"

echo "→ Building Elephant..."
if [ ! -d "$ELEPHANT_DIR/.git" ]; then
  git clone https://github.com/abenz1267/elephant.git --depth=1 "$ELEPHANT_DIR"
else
  git -C "$ELEPHANT_DIR" pull --ff-only
fi
cd "$ELEPHANT_DIR"
go build -o elephant ./cmd/elephant
cp elephant "$LOCAL_BIN/elephant"
chmod +x "$LOCAL_BIN/elephant"

echo "→ Building built-in Elephant providers..."
cd "$ELEPHANT_DIR"
for prov in \
  providerlist \
  desktopapplications \
  files \
  runner \
  calc \
  websearch \
  clipboard \
  symbols \
  unicode
do
  if [ -d "internal/providers/$prov" ]; then
    echo "   → $prov"
    (cd "internal/providers/$prov" && go build -buildmode=plugin -o "$prov.so")
    cp "internal/providers/$prov/$prov.so" "$PROVIDER_DIR/"
  else
    echo "   → skipping $prov, not found"
  fi
done

cat > "$HOME/.config/walker/config.toml" <<'CONFIG'
[providers]
default = [
  "desktopapplications",
  "runner",
  "websearch",
  "symbols",
  "unicode",
  "providerlist"
]

empty = [
  "desktopapplications"
]

[[providers.prefixes]]
prefix = ";"
provider = "providerlist"

[[providers.prefixes]]
prefix = ">"
provider = "runner"

[[providers.prefixes]]
prefix = "@"
provider = "websearch"

[[providers.prefixes]]
prefix = ":"
provider = "symbols"
CONFIG

cat > "$HOME/.config/systemd/user/elephant.service" <<'EOF_SERVICE'
[Unit]
Description=Elephant Backend for Walker
PartOf=graphical-session.target
After=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
Type=simple
ExecStart=%h/.local/bin/elephant
Restart=on-failure
RestartSec=3
Environment=PATH=/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=default.target
EOF_SERVICE

cat > "$HOME/.config/systemd/user/walker.service" <<'EOF_SERVICE'
[Unit]
Description=Walker Launcher Service
PartOf=graphical-session.target
After=elephant.service

[Service]
Type=simple
ExecStart=%h/.local/bin/walker --gapplication-service
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF_SERVICE

systemctl --user daemon-reload
systemctl --user enable --now elephant.service walker.service
systemctl --user restart elephant.service walker.service
sleep 2

echo "→ Installed providers:"
"$LOCAL_BIN/elephant" listproviders || true

echo "✅ Walker + Elephant klaar. Test met: walker"
