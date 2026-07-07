#!/usr/bin/env bash
set -euo pipefail

DOORAPI_DIR="$HOME/doorapi"
mkdir -p "$DOORAPI_DIR"

repos=(
  "miljoc/device_api"
  "miljoc/doorapi_front"
  "miljoc/thirdparty_api"
  "miljoc/doorapi_mobile"
  "miljoc/doorapi-k8s"
)

clone_one() {
  local repo="$1"
  local name="${repo##*/}"
  local target="$DOORAPI_DIR/$name"

  if [ -d "$target/.git" ]; then
    echo "$name bestaat al, pulling..."
    git -C "$target" pull --ff-only || true
    return 0
  fi

  echo "Cloning $repo -> $target"
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh repo clone "$repo" "$target"
  else
    git clone "https://github.com/$repo.git" "$target"
  fi
}

for repo in "${repos[@]}"; do
  clone_one "$repo"
done

echo
 echo "Repositories klaar in: $DOORAPI_DIR"
