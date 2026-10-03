"""Lucent target validation, live-session cleanup, and Limine installation."""
import json
from pathlib import Path
import shutil
import subprocess

import libcalamares


def command(*args):
    return subprocess.check_output(args, text=True).strip()


def mount_info(path):
    data = json.loads(command('findmnt', '--json', '--mountpoint', str(path),
                              '--output', 'SOURCE,FSTYPE,UUID'))
    return data['filesystems'][0]


def boot_layout(root):
    boot = mount_info(root / 'boot')
    system = mount_info(root)
    if boot['fstype'] != 'vfat' or system['fstype'] != 'ext4':
        raise ValueError('Use an ext4 root and a FAT32 EFI partition mounted at /boot (at least 1 GiB).')
    if not system.get('uuid') or not boot.get('uuid'):
        raise ValueError('Root and boot filesystems must have UUIDs.')
    if command('lsblk', '-ndo', 'TYPE', system['source']) != 'part':
        raise ValueError('This installer currently requires an unencrypted root partition without LVM.')
    if command('lsblk', '-ndo', 'PARTTYPE', boot['source']).lower() != 'c12a7328-f81f-11d2-ba4b-00a0c93ec93b':
        raise ValueError('The FAT32 /boot partition must have the EFI system partition type.')
    parent = command('lsblk', '-ndo', 'PKNAME', boot['source'])
    if not parent or '\n' in parent:
        raise ValueError('The boot partition must be on one physical disk.')
    disk = '/dev/' + parent
    if command('lsblk', '-ndo', 'PKNAME', system['source']) != parent:
        raise ValueError('Root and boot must be on the same disk.')
    data = json.loads(command('lsblk', '--json', '--tree', '--output', 'PATH,PARTTYPE,PARTN', disk))
    children = data['blockdevices'][0].get('children', [])
    bios = next((p for p in children if (p.get('parttype') or '').lower() ==
                 '21686148-6449-6e6f-744e-656564454649'), None)
    if bios is None:
        raise ValueError('A GPT BIOS boot partition is required. Use guided erase or create a BIOS boot partition manually.')
    return disk, str(bios['partn'])


def remove(root, name):
    path = root / name.lstrip('/')
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def cleanup(root):
    # These paths belong to the extracted target, never to the running live ISO.
    for name in (
        '/etc/plasmalogin.conf.d/autologin.conf',
        '/etc/sudoers.d/00-lucent-live',
        '/etc/systemd/system/getty@tty1.service.d/autologin.conf',
        '/etc/mkinitcpio.conf.d/archiso.conf',
        '/etc/systemd/system/cloud-init.target.wants',
        '/etc/systemd/system/multi-user.target.wants/choose-mirror.service',
        '/etc/systemd/system/multi-user.target.wants/pacman-init.service',
        '/etc/systemd/system/multi-user.target.wants/sshd.service',
        '/etc/systemd/system/multi-user.target.wants/livecd-talk.service',
        '/etc/systemd/system/sound.target.wants/livecd-alsa-unmuter.service',
        '/etc/systemd/system/etc-pacman.d-gnupg.mount',
        '/etc/systemd/system/systemd-time-wait-sync.service',
        '/etc/systemd/system/sysinit.target.wants/systemd-time-wait-sync.service',
        '/etc/systemd/journald.conf.d/volatile-storage.conf',
        '/etc/systemd/logind.conf.d/do-not-suspend.conf',
        '/etc/systemd/system-generators/systemd-gpt-auto-generator',
        '/etc/skel/Desktop/lucent-installer.desktop',
        '/usr/share/applications/lucent-installer.desktop',
        '/etc/motd',
    ):
        remove(root, name)
    subprocess.run(['chroot', str(root), 'userdel', '--remove', 'lucent'], check=True)
    subprocess.run(['chroot', str(root), 'passwd', '--lock', 'root'], check=True)
    (root / 'etc/lucent-installed').write_text('LucentOS\n')
    (root / 'etc/mkinitcpio.d/linux.preset').write_text(
        "ALL_kver='/boot/vmlinuz-linux'\nPRESETS=('default')\n"
        "default_image='/boot/initramfs-linux.img'\n")
    (root / 'etc/mkinitcpio.conf').write_text(
        'HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)\n')
    # Remove stale live seed data, including host identifiers and SSH keys.
    remove(root, '/var/lib/cloud')
    remove(root, '/var/lib/systemd/random-seed')
    for path in (root / 'etc/ssh').glob('ssh_host_*'):
        remove(root, str(path.relative_to(root)))
    subprocess.run(['chroot', str(root), 'pacman-key', '--init'], check=True, timeout=600)
    subprocess.run(['chroot', str(root), 'pacman-key', '--populate', 'archlinux'], check=True, timeout=600)


def run():
    try:
        root = Path(libcalamares.globalstorage.value('rootMountPoint'))
        if not root.is_absolute() or root == Path('/') or not root.is_mount():
            raise ValueError('Calamares did not supply a mounted target filesystem.')
        mode = libcalamares.job.configuration['mode']
        if mode == 'validate':
            boot_layout(root)
        elif mode == 'cleanup':
            cleanup(root)
        elif mode == 'boot':
            boot_layout(root)
            subprocess.run(['chroot', str(root), '/usr/local/bin/lucent-update-boot'], check=True)
        else:
            raise ValueError('Unknown Lucent installer stage: ' + mode)
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        return ('LucentOS installation could not continue', str(error))
    return None
