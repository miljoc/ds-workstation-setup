#!/usr/bin/env bash
set -euo pipefail

echo "== Installing Tela icon theme =="

THEME_DIR="$HOME/.local/share/icons"
CACHE_DIR="$HOME/.cache/doorapi-build/Tela-icon-theme"

mkdir -p "$THEME_DIR"
mkdir -p "$(dirname "$CACHE_DIR")"

if [ ! -d "$CACHE_DIR/.git" ]; then
    git clone https://github.com/vinceliuice/Tela-icon-theme.git "$CACHE_DIR"
else
    echo "Checking for Tela updates..."
    git -C "$CACHE_DIR" fetch origin

    LOCAL=$(git -C "$CACHE_DIR" rev-parse HEAD)
    REMOTE=$(git -C "$CACHE_DIR" rev-parse @{u})

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "Updating Tela..."
        git -C "$CACHE_DIR" pull --ff-only
    else
        echo "Tela already up to date."
    fi
fi

cd "$CACHE_DIR"

if [ ! -d "$THEME_DIR/Tela-pink-dark" ]; then
    echo "Installing Tela icon theme..."
    ./install.sh -a -d "$THEME_DIR"
else
    echo "Tela icon theme already installed."
fi

CURRENT_THEME=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")

if [ "$CURRENT_THEME" != "Tela-pink-dark" ]; then
    gsettings set org.gnome.desktop.interface icon-theme "Tela-pink-dark"
fi

echo "✓ Tela-pink-dark active"