#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="lucent"
iso_label="LUCENT_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="Lucent Codeworks <https://lucentcodeworks.com>"
iso_application="Lucent Live/Rescue DVD"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="lucent"
buildmodes=('iso')
bootmodes=('bios.limine' 'uefi.limine')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86,arm64' '-b' '1M' '-Xdict-size' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/usr/local/bin/lucent-installer"]="0:0:755"
  ["/usr/local/libexec/lucent-installer"]="0:0:755"
  ["/usr/local/bin/lucent-update-boot"]="0:0:755"
  ["/etc/skel/Desktop/lucent-installer.desktop"]="0:0:755"
  ["/etc/shadow"]="0:0:400"
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers.d"]="0:0:750"
  ["/etc/sudoers.d/00-lucent-live"]="0:0:440"
  ["/root"]="0:0:750"
  ["/root/.automated_script.sh"]="0:0:755"
  ["/root/.gnupg"]="0:0:700"
  ["/usr/local/bin/choose-mirror"]="0:0:755"
  ["/usr/local/bin/Installation_guide"]="0:0:755"
  ["/usr/local/bin/livecd-sound"]="0:0:755"
)

# Profile-local boot modes for archiso versions without native Limine support.
source "$(dirname "${BASH_SOURCE[0]}")/limine/archiso.sh"
