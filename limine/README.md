# Limine ISO integration

Install `archiso` and `limine` on the build host, then run `./build.sh`.
Direct `mkarchiso` builds also work: `profiledef.sh` loads `archiso.sh`, which
adds profile-local Limine boot modes and wraps archiso's ISO writer to run
`limine bios-install` before archiso removes its working directory.

The hybrid image supports BIOS and UEFI boot from optical media and USB.
Its layout follows [Limine's hybrid ISO instructions](https://github.com/Limine-Bootloader/Limine/blob/v12.x/USAGE.md#biosuefi-hybrid-iso-creation).
The integration uses archiso internal functions, verified against archiso 90;
check it when upgrading archiso. Microcode is included by the existing
mkinitcpio `microcode` hook.

The menu includes normal and speakup live sessions, BIOS and UEFI Memtest86+,
and the UEFI shell. It requires `limine`, `memtest86+`, `memtest86+-efi`, and
`edk2-shell` in `packages.x86_64`. The previous Syslinux PXE menus are removed;
this profile builds an ISO only.

To test UEFI with the existing QEMU launcher:

```sh
./run.sh -bios /usr/share/edk2/x64/OVMF.4m.fd
```
