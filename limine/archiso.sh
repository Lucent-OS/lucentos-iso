#!/usr/bin/env bash
# Sourced by profiledef.sh inside mkarchiso; uses archiso's internal variables.
# Hybrid layout follows /usr/share/doc/limine/USAGE.md.

_validate_requirements_bootmode_bios.limine() {
    local package
    if ! command -v limine >/dev/null; then
        (( validation_error+=1 ))
        _msg_error "Install the 'limine' package on the build host." 0
    fi
    for package in limine memtest86+ memtest86+-efi edk2-shell; do
        if [[ ! " ${pkg_list[*]} " == *" ${package} "* ]]; then
            (( validation_error+=1 ))
            _msg_error "The Limine menu requires '${package}' in the package list." 0
        fi
    done
}

_validate_requirements_bootmode_uefi.limine() {
    if [[ ${arch} != x86_64 ]]; then
        (( validation_error+=1 ))
        _msg_error 'This Limine profile supports x86_64 only.' 0
    fi
}

_make_bootmode_bios.limine() {
    local assets="${pacstrap_dir}/usr/share/limine"
    install -d -m 0755 "${isofs_dir}/boot/limine" "${isofs_dir}/EFI/BOOT"
    install -m 0644 "${assets}/limine-bios.sys" "${assets}/limine-bios-cd.bin" \
        "${assets}/limine-uefi-cd.bin" "${isofs_dir}/boot/limine/"
    install -m 0644 "${assets}/BOOTX64.EFI" "${assets}/BOOTIA32.EFI" "${isofs_dir}/EFI/BOOT/"
    sed -e "s|%INSTALL_DIR%|${install_dir}|g" -e "s|%ARCH%|${arch}|g" \
        -e "s|%ARCHISO_UUID%|${iso_uuid}|g" \
        "${profile}/limine/limine.conf" >"${isofs_dir}/boot/limine/limine.conf"
    install -d -m 0755 "${isofs_dir}/boot/memtest86+"
    install -m 0644 "${boot_dir}/memtest86+/memtest.bin" \
        "${boot_dir}/memtest86+/memtest.efi" "${isofs_dir}/boot/memtest86+/"
    install -m 0644 "${pacstrap_dir}/usr/share/licenses/spdx/GPL-2.0-only.txt" \
        "${isofs_dir}/boot/memtest86+/LICENSE"
    install -m 0644 "${pacstrap_dir}/usr/share/edk2-shell/x64/Shell_Full.efi" "${isofs_dir}/shellx64.efi"
}

_make_bootmode_uefi.limine() { :; }

# Limine boots the ISO filesystem directly; no GRUB compatibility files needed.
_make_common_grubenv_and_loopbackcfg() { :; }

_add_xorrisofs_options_bios.limine() {
    xorrisofs_options+=(
        -b boot/limine/limine-bios-cd.bin
        -no-emul-boot -boot-load-size 4 -boot-info-table
        -hfsplus -apm-block-size 2048
    )
}

_add_xorrisofs_options_uefi.limine() {
    xorrisofs_options+=(
        --efi-boot boot/limine/limine-uefi-cd.bin
        -efi-boot-part --efi-boot-image --protective-msdos-label
    )
}

# Wrap archiso's ISO writer so direct mkarchiso invocations also install the
# BIOS disk stages required when the ISO is written to a USB drive.
if declare -F _build_iso_image >/dev/null; then
    eval "$(declare -f _build_iso_image | sed '1s/_build_iso_image/_limine_build_iso_image/')"
    _build_iso_image() {
        _limine_build_iso_image
        limine bios-install "${out_dir}/${image_name}"
    }
fi
