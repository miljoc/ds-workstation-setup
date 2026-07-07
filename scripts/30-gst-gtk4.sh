#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

if [ -x "$HOME/.local/bin/mise" ]; then
  eval "$($HOME/.local/bin/mise activate bash)"
fi

echo "== Ensure rustup stable =="
if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
  export PATH="$HOME/.cargo/bin:$PATH"
fi

rustup toolchain install stable
rustup default stable

# Force cargo-c to use rustup cargo, not mise shim cargo
export RUSTUP_TOOLCHAIN=stable
export CARGO="$HOME/.cargo/bin/cargo"
export RUSTC="$HOME/.cargo/bin/rustc"
export PATH="$HOME/.cargo/bin:$PATH"

echo "Using cargo: $(command -v cargo)"
cargo --version
rustup show

if gst-inspect-1.0 gtk4paintablesink >/dev/null 2>&1; then
  echo "gtk4paintablesink already installed."
  exit 0
fi

sudo dnf install -y \
  git gcc gcc-c++ make clang pkgconf-pkg-config \
  glib2-devel gstreamer1-devel gstreamer1-plugins-base-devel \
  gtk4-devel graphene-devel cairo-devel pango-devel

if ! command -v cargo-cbuild >/dev/null 2>&1; then
  "$HOME/.cargo/bin/cargo" install cargo-c
fi

WORKDIR="$HOME/.cache/doorapi-build"
REPO_DIR="$WORKDIR/gst-plugins-rs"

mkdir -p "$WORKDIR"

if [ ! -d "$REPO_DIR/.git" ]; then
  git clone https://gitlab.freedesktop.org/gstreamer/gst-plugins-rs.git "$REPO_DIR"
else
  git -C "$REPO_DIR" pull --ff-only
fi

cd "$REPO_DIR"

"$HOME/.cargo/bin/cargo" cbuild -p gst-plugin-gtk4 --release
sudo env \
  "PATH=$HOME/.cargo/bin:$PATH" \
  "RUSTUP_TOOLCHAIN=stable" \
  "CARGO=$HOME/.cargo/bin/cargo" \
  "RUSTC=$HOME/.cargo/bin/rustc" \
  "$HOME/.cargo/bin/cargo" cinstall -p gst-plugin-gtk4 --release --prefix=/usr

sudo ldconfig

gst-inspect-1.0 gtk4paintablesink

echo "gtk4paintablesink installed."
