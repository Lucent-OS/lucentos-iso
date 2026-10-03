#!/usr/bin/env bash
# Build the LucentOS ISO from this archiso profile.
#
# Usage: ./build.sh
#   WORK_DIR  scratch directory for mkarchiso (default: ./work, wiped on every run)
#   OUT_DIR   where the finished ISO lands  (default: ./out)

set -euo pipefail

PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${WORK_DIR:-${PROFILE_DIR}/work}"
OUT_DIR="${OUT_DIR:-${PROFILE_DIR}/out}"

# mkarchiso must run as root; re-exec through sudo, preserving our env overrides.
if [[ ${EUID} -ne 0 ]]; then
    exec sudo --preserve-env=WORK_DIR,OUT_DIR "$0" "$@"
fi

if ! command -v mkarchiso >/dev/null; then
    echo "error: mkarchiso not found (install the 'archiso' package)" >&2
    exit 1
fi

clean_work_dir() {
    [[ -e ${WORK_DIR} ]] || return 0

    # A failed build can leave proc/sys/dev mounted inside the chroot. Unmount
    # them first so the rm below never descends into a live filesystem.
    local mounts
    mounts="$(findmnt --list --noheadings --output TARGET | grep -F "${WORK_DIR}/" | sort -r || true)"
    if [[ -n ${mounts} ]]; then
        echo "==> Unmounting leftover mounts in ${WORK_DIR}"
        xargs -r -d '\n' umount -R <<<"${mounts}"
    fi

    echo "==> Removing work directory ${WORK_DIR}"
    rm -rf --one-file-system -- "${WORK_DIR}"
}

clean_work_dir
mkdir -p "${OUT_DIR}"

echo "==> Building ISO (work: ${WORK_DIR}, out: ${OUT_DIR})"
mkarchiso -v -r -w "${WORK_DIR}" -o "${OUT_DIR}" "${PROFILE_DIR}"

# mkarchiso -r removes the work dir on success; make sure nothing is left behind.
clean_work_dir

# Hand ownership of the output back to the invoking user.
if [[ -n ${SUDO_UID:-} ]]; then
    chown -R "${SUDO_UID}:${SUDO_GID}" "${OUT_DIR}"
fi

echo "==> Done:"
ls -lh "${OUT_DIR}"/*.iso