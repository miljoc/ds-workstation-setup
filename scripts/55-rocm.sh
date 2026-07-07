#!/usr/bin/env bash
set -euo pipefail

echo "== Installing ROCm userspace for AMD Radeon =="

if command -v rocminfo >/dev/null 2>&1 && rocminfo >/dev/null 2>&1; then
  echo "ROCm already working. Skipping ROCm install."
  rocminfo | grep -E "gfx1100|Radeon RX|Agent" || true
  exit 0
fi

echo "ROCm not working or incomplete. Continuing install/repair..."

sudo dnf install -y wget curl

ROCM_VERSION="7.2.4"
ROCM_RPM="amdgpu-install-${ROCM_VERSION}.70204-1.el10.noarch.rpm"
ROCM_URL="https://repo.radeon.com/amdgpu-install/${ROCM_VERSION}/rhel/10/${ROCM_RPM}"

cd /tmp

if [ ! -f "$ROCM_RPM" ]; then
  wget "$ROCM_URL"
fi

sudo dnf install -y "/tmp/$ROCM_RPM"
sudo dnf clean all

sudo amdgpu-install --usecase=rocm --no-dkms -y

sudo dnf install -y \
  hsa-rocr \
  hsa-rocr-devel \
  rocminfo \
  rocm-smi \
  rocm-hip-runtime \
  rocm-hip-runtime-devel \
  hipcc || true

sudo ldconfig

sudo usermod -aG render,video "$USER" || true

sudo dnf install -y rocminfo rocm-smi || true

command -v rocm-smi >/dev/null && rocm-smi >/dev/null && echo "✓ rocm-smi" || echo "✗ rocm-smi"

echo
echo
echo "=== ROCm Validation ==="

rocminfo >/dev/null && echo "✓ rocminfo"

rocm-smi >/dev/null && echo "✓ rocm-smi"

hipconfig --version >/dev/null && echo "✓ HIP"

echo
echo "ROCm installed. Reboot required before rocminfo works reliably."
