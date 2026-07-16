#!/usr/bin/env bash
set -Eeuo pipefail

WIZARD_BUILD="v3.1-walker-elephant-bootfix-2026-07-16"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${WORKSTATION_LOG_FILE:-$HOME/workstation-setup.log}"
CURRENT_STEP="Initialisatie"
INSTALL_FINISHED=0

mkdir -p "$(dirname "$LOG_FILE")"
: > "$LOG_FILE"

# Parse explicit non-interactive options. Interactive mode is the default and
# MUST show the checklist. We no longer silently fall back to installing all
# components when a TTY or whiptail is unavailable.
NON_INTERACTIVE=0
CLI_COMPONENTS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      NON_INTERACTIVE=1
      CLI_COMPONENTS="core media uxplay gnomeext templates launcher podman extra rocm ollama"
      shift
      ;;
    --components)
      [[ $# -ge 2 ]] || { echo "--components vereist een lijst" >&2; exit 2; }
      NON_INTERACTIVE=1
      CLI_COMPONENTS="$2"
      shift 2
      ;;
    --help|-h)
      cat <<'EOF'
Gebruik:
  ./install.sh                 Toon de interactieve Whiptail-wizard
  ./install.sh --all           Installeer alle standaardonderdelen zonder wizard
  ./install.sh --components "core media uxplay"
EOF
      exit 0
      ;;
    *)
      echo "Onbekende optie: $1" >&2
      exit 2
      ;;
  esac
done

pause_before_exit() {
  if [[ -r /dev/tty && -w /dev/tty ]]; then
    printf '\nDruk op Enter om deze terminal te sluiten...' > /dev/tty
    IFS= read -r _ < /dev/tty || true
  elif [[ -t 0 ]]; then
    echo
    read -rp "Druk op Enter om deze terminal te sluiten..." _ || true
  fi
}

on_error() {
  local exit_code=$?
  trap - ERR
  echo
  echo "============================================================"
  echo "INSTALLATIE MISLUKT"
  echo "Stap: $CURRENT_STEP"
  echo "Exitcode: $exit_code"
  echo "Log: $LOG_FILE"
  echo "============================================================"
  pause_before_exit
  exit "$exit_code"
}
trap on_error ERR

run() {
  CURRENT_STEP="$1"
  echo
  echo "============================================================"
  echo "== $CURRENT_STEP"
  echo "============================================================"
  bash "$ROOT_DIR/scripts/$2"
}

selected() {
  local needle="$1"
  [[ " $SELECTIONS " == *" $needle "* ]]
}

ensure_tui() {
  if ! command -v whiptail >/dev/null 2>&1; then
    echo "Whiptail wordt geinstalleerd voor de setupwizard..."
    sudo dnf install -y newt
  fi
}

show_tui() {
  ensure_tui

  if [[ ! -e /dev/tty ]]; then
    echo "FOUT: /dev/tty ontbreekt; interactieve wizard kan niet starten." >&2
    exit 2
  fi

  local tmp status
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN

  # Write an unmistakable pre-wizard banner directly to the controlling TTY.
  {
    clear
    echo "============================================================"
    echo " Doorsecure Workstation Setup Wizard ($WIZARD_BUILD)"
    echo "============================================================"
    echo "De checklist wordt nu geopend..."
    sleep 1
  } > /dev/tty

  set +e
  whiptail \
    --title "Doorsecure Developer Workstation" \
    --backtitle "Rocky Linux 10 single-command setup - $WIZARD_BUILD" \
    --separate-output \
    --checklist "Selecteer onderdelen. Spatie = aan/uit, Enter = installeren." \
    25 90 16 \
    "core"       "Systeempakketten, repositories en VS Code" ON \
    "media"      "Nautilus media tools, OCR, QR, WebM en WebP" ON \
    "uxplay"     "UxPlay vanaf source + legacy poorten" ON \
    "gnomeext"   "Shotzy en extra GNOME-extensies" ON \
    "templates"  "Developer templates voor Nieuw document" ON \
    "launcher"   "Walker + Elephant launcher" ON \
    "podman"     "Podman en containers" ON \
    "extra"      "Extra desktop-apps" ON \
    "rocm"       "ROCm userspace en GPU-monitor" ON \
    "ollama"     "Ollama, Open WebUI en lokale modellen" ON \
    "repos"      "Private DoorAPI repositories clonen" OFF \
    2>"$tmp" </dev/tty >/dev/tty
  status=$?
  set -e

  if [[ $status -ne 0 ]]; then
    echo "Setup geannuleerd." > /dev/tty
    rm -f "$tmp"
    exit 0
  fi

  SELECTIONS="$(tr '\n' ' ' < "$tmp" | xargs)"
  rm -f "$tmp"

  if [[ -z "$SELECTIONS" ]]; then
    echo "Geen onderdelen geselecteerd. Setup gestopt." > /dev/tty
    exit 0
  fi

  {
    echo
    echo "Geselecteerd: $SELECTIONS"
    echo
  } > /dev/tty
}

# The wizard is intentionally displayed BEFORE stdout/stderr are redirected to
# tee. This is the reliable, standard whiptail pattern and prevents wrappers or
# process substitution from stealing its controlling terminal.
if [[ $NON_INTERACTIVE -eq 1 ]]; then
  SELECTIONS="$CLI_COMPONENTS"
else
  show_tui
fi

# Start logging only after the interactive checklist has completed.
exec > >(tee -a "$LOG_FILE") 2>&1

export INSTALL_ROCM="N"
selected rocm && export INSTALL_ROCM="Y"

run "Backup existing GNOME and user state" "01-backup-user-state.sh"

if selected core; then
  run "Repositories / RPM Fusion" "05-repos.sh"
  run "System packages" "00-system.sh"
  run "VS Code" "10-vscode.sh"
  run "Mise / Elixir / Node / Rust" "20-mise.sh"
  run "Bash config" "21-bash-config.sh"
  run "GStreamer GTK4 plugin" "30-gst-gtk4.sh"
  run "Flatpak apps" "40-flatpak.sh"
  run "Tela icon theme" "45-tela-icons.sh"
fi

selected extra && run "Extra apps" "42-extra-apps.sh"

if selected media; then
  run "Nautilus media tools" "31-nautilus-media-tools.sh"
  run "Native WebM and WebP support" "34-native-media-support.sh"
fi

selected uxplay && run "UxPlay AirPlay receiver" "32-uxplay.sh"

if selected gnomeext; then
  run "Shotzy screenshot OCR and QR" "33-shotzy.sh"
  run "GNOME productivity extensions" "89-gnome-extensions.sh"
fi

selected templates && run "Nautilus developer templates" "35-nautilus-templates.sh"
selected podman && run "Podman containers" "50-podman.sh"

if selected rocm; then
  run "ROCm userspace" "55-rocm.sh"
else
  echo "ROCm overgeslagen."
fi

if selected ollama; then
  run "Ollama / Open WebUI" "60-ollama.sh"
else
  echo "Ollama en Open WebUI overgeslagen."
fi

if selected core; then
  run "VS Code config" "70-vscode-config.sh"
  run "GNOME media" "93-gnome-media.sh"
  run "GNOME extensions restore" "90-gnome.sh"
fi

if selected launcher; then
  run "Walker launcher" "91-launcher.sh"
  run "Super + Space" "92-super-space.sh"
fi

if selected repos; then
  CURRENT_STEP="GitHub authenticatie"
  if ! command -v gh >/dev/null 2>&1; then
    sudo dnf install -y gh || sudo dnf install -y github-cli
  fi
  gh auth status >/dev/null 2>&1 || gh auth login
  gh auth setup-git || true
  run "Clone private DoorAPI repositories" "95-clone-repos.sh"
  run "VS Code workspace" "96-vscode-workspace.sh"
fi

run "Install workstation CLI" "97-install-workstation-cli.sh"
run "Final checks" "99-check.sh"

INSTALL_FINISHED=1
trap - ERR

echo
echo "============================================================"
echo "INSTALLATIE SUCCESVOL VOLTOOID"
echo "Log: $LOG_FILE"
echo "Een herstart of opnieuw inloggen wordt aanbevolen."
echo "============================================================"
pause_before_exit
