#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ask_yes_no() {
  local question="$1"
  local default="${2:-N}"
  local answer
  while true; do
    read -rp "$question [$default]: " answer
    answer="${answer:-$default}"
    case "$answer" in
      [Yy]|[Yy][Ee][Ss]|[Jj]|[Jj][Aa]) return 0 ;;
      [Nn]|[Nn][Oo]|[Nn][Ee][Ee]) return 1 ;;
      *) echo "Antwoord met Y of N." ;;
    esac
  done
}

run() {
  echo
  echo "============================================================"
  echo "== $1"
  echo "============================================================"
  bash "$ROOT_DIR/scripts/$2"
}

INSTALL_ROCM="N"
INSTALL_OLLAMA="N"
INSTALL_EXTRA_APPS="N"
CLONE_REPOS="N"

if ask_yes_no "Wil je ROCm installeren?" "Y"; then
  INSTALL_ROCM="Y"
fi

if ask_yes_no "Wil je Ollama, Open WebUI en modellen installeren?" "Y"; then
  INSTALL_OLLAMA="Y"
fi

if ask_yes_no "Wil je extra handy pakketten installeren?" "Y"; then
  INSTALL_EXTRA_APPS="Y"
fi

if ask_yes_no "Wil je DoorAPI git repositories clonen?" "Y"; then
  CLONE_REPOS="Y"
fi

run "Repositories / RPM Fusion" "05-repos.sh"
run "System packages" "00-system.sh"

if [ "$INSTALL_EXTRA_APPS" = "Y" ]; then
  run "Extra apps" "42-extra-apps.sh"
else
  echo "Skipping extra apps."
fi

run "VS Code" "10-vscode.sh"
run "Mise / Elixir / Node / Rust" "20-mise.sh"
run "Bash config" "21-bash-config.sh"
run "GStreamer GTK4 plugin" "30-gst-gtk4.sh"
run "Flatpak apps" "40-flatpak.sh"
run "Tela icon theme" "45-tela-icons.sh"
run "Podman containers" "50-podman.sh"

if [ "$INSTALL_ROCM" = "Y" ]; then
  run "ROCm userspace" "55-rocm.sh"
else
  echo "Skipping ROCm."
fi

if [ "$INSTALL_OLLAMA" = "Y" ]; then
  run "Ollama / Open WebUI" "60-ollama.sh"
else
  echo "Skipping Ollama/Open WebUI/models."
fi

run "VS Code config" "70-vscode-config.sh"
run "GNOME media" "93-gnome-media.sh"
run "GNOME extensions restore" "90-gnome.sh"
run "Walker launcher" "91-launcher.sh"
run "Super + Space" "92-super-space.sh"

if [ "$CLONE_REPOS" = "Y" ]; then
  if ! command -v gh >/dev/null 2>&1; then
    sudo dnf install -y gh || sudo dnf install -y github-cli
  fi
  if ! gh auth status >/dev/null 2>&1; then
    gh auth login
  fi
  gh auth setup-git || true
  run "Clone DoorAPI repositories" "95-clone-repos.sh"
  run "VS Code workspace" "96-vscode-workspace.sh"
else
  echo "Skipping DoorAPI repo cloning."
fi

run "Final checks" "99-check.sh"

echo
echo "😵‍💫 Done. Reboot aanbevolen."
