#!/usr/bin/env bash
set -euo pipefail
installer_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if (( EUID == 0 )); then
    echo 'Run this script as a regular user; makepkg must not run as root.' >&2
    exit 1
fi
cd "${installer_dir}/package"
makepkg --syncdeps --needed --cleanbuild --clean
mkdir -p "${installer_dir}/repo"
mapfile -t packages < <(makepkg --packagelist)
repo_packages=()
for package in "${packages[@]}"; do
    cp -- "$package" "${installer_dir}/repo/"
    repo_packages+=("${installer_dir}/repo/$(basename "$package")")
done
repo-add "${installer_dir}/repo/lucent-installer.db.tar.gz" "${repo_packages[@]}"
