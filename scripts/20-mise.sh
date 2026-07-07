#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$HOME/.cargo/bin:$PATH"

echo "== Installing mise =="

if [ ! -x "$HOME/.local/bin/mise" ]; then
  curl https://mise.run | sh
fi

mkdir -p "$HOME/doorapi"

cat > "$HOME/doorapi/.mise.toml" <<'MISE'
[tools]
erlang = "27.3.4"
elixir = "1.18.4-otp-27"
node = "22"
rust = "stable"
MISE

cd "$HOME/doorapi"

mise trust "$HOME/doorapi/.mise.toml" || true

echo "== Setting global mise versions =="

mise use -g erlang@27.3.4
mise use -g elixir@1.18.4-otp-27
mise use -g node@22
mise use -g rust@stable

mise install

echo "== Installing rustup fallback =="

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
fi

export PATH="$HOME/.cargo/bin:$PATH"

rustup toolchain install stable
rustup default stable

echo "== Rust globals =="

rustup show
rustup default
rustc --version
cargo --version

echo "== Mise current =="

mise current
