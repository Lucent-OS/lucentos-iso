#!/usr/bin/env bash
# Boot the latest built ISO in QEMU (BIOS mode).
# Usage: ./run.sh [path/to/image.iso] [extra QEMU options...]
#   OUT_DIR  build output directory (default: ./out beside this script)
#   MEMORY   guest RAM in MiB (default: 4096)
#   CPUS     guest CPU count (default: 2)
# Example: ./run.sh out/archlinux-2026.10.03-x86_64.iso -display gtk

set -euo pipefail

PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${OUT_DIR:-${PROFILE_DIR}/out}"

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  sed -n '2,7s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"
  exit 0
fi

if [[ $# -gt 0 && $1 != -* ]]; then
  ISO_PATH="$1"
  shift
else
  ISO_PATH=""
  shopt -s nullglob
  for candidate in "${OUT_DIR}"/*.iso; do
    if [[ -z ${ISO_PATH} || ${candidate} -nt ${ISO_PATH} ]]; then
      ISO_PATH="${candidate}"
    fi
  done
fi

if [[ -z ${ISO_PATH} || ! -f ${ISO_PATH} || ! -r ${ISO_PATH} ]]; then
  echo "error: no readable ISO found; run ./build.sh first or supply an ISO path" >&2
  exit 1
fi

if ! command -v qemu-system-x86_64 >/dev/null; then
  echo "error: qemu-system-x86_64 not found (install the 'qemu-desktop' package)" >&2
  exit 1
fi

acceleration=(-accel tcg)
if [[ -r /dev/kvm && -w /dev/kvm ]]; then
  acceleration=(-accel kvm -cpu host)
else
  echo "==> KVM unavailable; using software emulation"
fi

echo "==> Booting ${ISO_PATH}"
exec qemu-system-x86_64 \
  -name LucentOS \
  "${acceleration[@]}" \
  -m "${MEMORY:-4096}" \
  -smp "${CPUS:-2}" \
  -boot order=d \
  -cdrom "${ISO_PATH}" \
  -nic user,model=virtio-net-pci \
  "$@"