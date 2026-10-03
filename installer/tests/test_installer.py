"""Checks target guards and boot layout without writing to any disk."""
import importlib.util
import json
from pathlib import Path
import sys
import types
import unittest
from unittest.mock import patch

PROJECT = Path(__file__).resolve().parents[2]
MODULE = PROJECT / 'airootfs/etc/calamares/modules/lucent/main.py'
sys.modules['libcalamares'] = types.SimpleNamespace(
    globalstorage=types.SimpleNamespace(value=lambda _: '/'),
    job=types.SimpleNamespace(configuration={'mode': 'cleanup'}),
)
spec = importlib.util.spec_from_file_location('lucent', MODULE)
lucent = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lucent)


class InstallerTests(unittest.TestCase):
    def mount_info(self, path):
        if path.name == 'boot':
            return {'source': '/dev/nvme0n1p2', 'fstype': 'vfat', 'uuid': 'ABCD-1234'}
        return {'source': '/dev/nvme0n1p3', 'fstype': 'ext4', 'uuid': 'root-uuid'}

    def command(self, *args):
        if 'TYPE' in args:
            return 'part'
        if 'PARTTYPE' in args:
            return 'c12a7328-f81f-11d2-ba4b-00a0c93ec93b'
        if 'PKNAME' in args:
            return 'nvme0n1'
        return json.dumps({'blockdevices': [{'children': [
            {'parttype': '21686148-6449-6e6f-744e-656564454649', 'partn': 1}
        ]}]})

    def test_nvme_hybrid_layout(self):
        with patch.object(lucent, 'mount_info', self.mount_info), patch.object(lucent, 'command', self.command):
            self.assertEqual(lucent.boot_layout(Path('/target')), ('/dev/nvme0n1', '1'))

    def test_missing_bios_partition(self):
        def no_bios(*args):
            if '--json' in args:
                return '{"blockdevices": [{"children": []}]}'
            return self.command(*args)
        with patch.object(lucent, 'mount_info', self.mount_info), patch.object(lucent, 'command', no_bios):
            with self.assertRaisesRegex(ValueError, 'BIOS boot partition'):
                lucent.boot_layout(Path('/target'))

    def test_non_fat_boot_rejected(self):
        with patch.object(lucent, 'mount_info', return_value={'fstype': 'ext4'}):
            with self.assertRaisesRegex(ValueError, 'FAT32'):
                lucent.boot_layout(Path('/target'))

    def test_live_root_cannot_be_cleaned(self):
        with patch.object(lucent, 'cleanup') as cleanup:
            result = lucent.run()
            self.assertIn('mounted target', result[1])
            cleanup.assert_not_called()

    def test_encrypted_root_rejected(self):
        def crypt(*args):
            return 'crypt' if 'TYPE' in args else self.command(*args)
        with patch.object(lucent, 'mount_info', self.mount_info), patch.object(lucent, 'command', crypt):
            with self.assertRaisesRegex(ValueError, 'unencrypted'):
                lucent.boot_layout(Path('/target'))


if __name__ == '__main__':
    unittest.main()
