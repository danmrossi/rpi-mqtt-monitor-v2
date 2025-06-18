import unittest
from unittest import mock
import subprocess
import builtins
import os

import importlib.util
from pathlib import Path
import sys
import types

SRC_DIR = Path(__file__).parents[1] / "src"
sys.path.insert(0, str(SRC_DIR))
sys.modules['config'] = types.SimpleNamespace(use_availability=False, ext_sensors=False, version="0")

spec = importlib.util.spec_from_file_location("monitor", str(SRC_DIR / "rpi-cpu2mqtt.py"))
monitor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(monitor)

import update

class TestFunctions(unittest.TestCase):
    def test_check_sys_clock_speed(self):
        mock_data = '1500000\n'
        with mock.patch.object(builtins, 'open', mock.mock_open(read_data=mock_data)):
            self.assertEqual(monitor.check_sys_clock_speed(), 1500)

    def test_get_assignments(self):
        with open('tmp_config.py', 'w') as f:
            f.write('var1 = 1\nvar2 = "test"\n')
        try:
            result = update.get_assignments('tmp_config.py')
            self.assertEqual(result['var1'], 1)
            self.assertEqual(result['var2'], 'test')
        finally:
            os.remove('tmp_config.py')

    def test_check_git_version_remote(self):
        mock_completed = mock.Mock(stdout='v1.0\nv0.9\n', returncode=0)
        with mock.patch('subprocess.run', return_value=mock_completed) as m:
            version = update.check_git_version_remote('/tmp')
            self.assertEqual(version, 'v1.0')
            expected_calls = [
                mock.call([
                    '/usr/bin/git', '-C', '/tmp', 'fetch', '--tags'
                ], check=True, stdout=mock.ANY, stderr=mock.ANY, text=True),
                mock.call([
                    '/usr/bin/git', '-C', '/tmp', 'tag', '--sort=-v:refname'
                ], check=True, stdout=mock.ANY, stderr=mock.ANY, text=True)
            ]
            m.assert_has_calls(expected_calls)

    def test_install_requirements_error(self):
        with mock.patch('subprocess.run', side_effect=subprocess.CalledProcessError(1, 'cmd')):
            with self.assertRaises(SystemExit):
                update.install_requirements('/tmp')

    def test_sanitize_numeric(self):
        self.assertEqual(monitor.sanitize_numeric(10), 10)
        self.assertEqual(monitor.sanitize_numeric(None), 0)
        self.assertEqual(monitor.sanitize_numeric(float('nan')), 0)

    def test_build_device_info(self):
        with mock.patch.object(monitor, 'hostname', 'test_host'), \
             mock.patch.object(monitor, 'check_model_name', return_value='Pi Model'), \
             mock.patch.object(monitor, 'get_manufacturer', return_value='ACME'), \
             mock.patch.object(monitor, 'get_os', return_value='TestOS'), \
             mock.patch.object(monitor, 'get_mac_address', return_value='00-11-22-33-44-55'), \
             mock.patch.object(monitor, 'get_network_ip', return_value='192.168.1.2'):

            expected = {
                'identifiers': ['test_host'],
                'manufacturer': 'github.com/danmrossi',
                'model': f'RPi MQTT Monitor V2 {monitor.config.version}',
                'name': 'test_host',
                'sw_version': 'TestOS',
                'hw_version': 'Pi Model by ACME',
                'configuration_url': 'https://github.com/danmrossi/rpi-mqtt-monitor-v2',
                'connections': [['mac', '00-11-22-33-44-55'], ['ip', '192.168.1.2']]
            }
            self.assertEqual(monitor.build_device_info(), expected)

if __name__ == '__main__':
    unittest.main()

