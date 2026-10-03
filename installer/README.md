# LucentOS graphical installer

The live image includes a Lucent-branded Calamares installer, available from
the application menu and the desktop as **Install LucentOS**. The launcher
connects the privileged installer to the live user's Wayland display.

## Build

Calamares is not in this profile's Arch repositories. A pinned package recipe
builds Calamares 3.4.2 with Qt 6 and Python modules from a checksum-verified
upstream release. The recipe is adapted from the
[AUR Calamares package](https://aur.archlinux.org/packages/calamares).

Install `base-devel`, `archiso`, and `limine` on the build host. Then run these
commands from the project directory in an interactive terminal:

```sh
./installer/build-package.sh
./build.sh
```

The first command runs as your normal user and uses sudo for missing build
dependencies. It produces a local pacman repository in `installer/repo`.
The ISO builder inserts its absolute path into a temporary pacman
configuration. It checks for this repository before clearing its work directory.
The local repository permits unsigned local packages; official repositories
retain their normal signature requirements.

Use `build.sh` for this profile: a direct `mkarchiso` invocation must supply
`-C` with a pacman configuration that resolves `@LUCENT_INSTALLER_REPO@`.

## Installation behavior

The installer copies the ISO's system offline, including Plasma and the
development tools, then creates the chosen user. It restores a normal
mkinitcpio preset, builds the installed initramfs, initializes the Arch
keyring, and configures Limine. No GRUB or systemd-boot installation is used.

Guided erase creates GPT partitions suitable for BIOS and UEFI: a BIOS boot
partition, a 1 GiB FAT32 EFI system partition mounted at `/boot`, and an ext4
root. Installation currently requires an unencrypted ext4 root without LVM,
with root and boot on the same disk. For manual partitioning, reproduce those
requirements; the custom validation job checks them after partition mounting
and before copying the system. Other layouts are not supported yet.

The installed system removes the live user, passwordless live sudo rule,
live autologin, root console autologin, installer launchers, and live boot
hooks. The new user receives password-protected sudo through the wheel group;
root login is locked. A pacman hook refreshes Limine files and BIOS stages
after kernel or Limine updates.

Branding lives in `airootfs/etc/calamares/branding/lucent`. The logo and
welcome artwork are editable SVGs; the installation slideshow is QML.

## Validation

Run the disk-free installer guard tests with:

```sh
python3 -m unittest discover -s installer/tests -v
```

Source checksum verification, module-schema validation, launcher validation,
shell parsing, and guard tests have passed. Calamares compilation and a full
installation have not been verified on this machine because dependency
installation needs interactive sudo.

Before distributing an ISO, test installation onto a disposable virtual disk
in both BIOS and UEFI mode. Detach the ISO and verify that Limine boots the
installed Plasma system, the chosen user can log in and use sudo, the live
account is absent, and a kernel update leaves the installation bootable.
