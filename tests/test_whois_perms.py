import os
import sys
import types
import importlib.util

# Add repository root to sys.path
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

# Provide a dummy termcolor module if it's not installed
if 'termcolor' not in sys.modules:
    dummy = types.ModuleType('termcolor')
    dummy.colored = lambda text, color=None: text
    sys.modules['termcolor'] = dummy

spec = importlib.util.spec_from_file_location(
    'whois_perms', os.path.join(ROOT_DIR, 'Utilities', 'whois_perms.py')
)
whois_perms = importlib.util.module_from_spec(spec)
spec.loader.exec_module(whois_perms)
expand_cidr = whois_perms.expand_cidr
strip_color_codes = whois_perms.strip_color_codes
compute_max_widths = whois_perms.compute_max_widths

def test_expand_cidr_single_ip():
    assert expand_cidr('192.168.1.1') == ['192.168.1.1']

def test_expand_cidr_cidr_range():
    result = expand_cidr('10.0.0.0/30')
    assert len(result) == 4
    assert result == ['10.0.0.0', '10.0.0.1', '10.0.0.2', '10.0.0.3']

def test_strip_color_codes():
    text = "\x1b[31merror\x1b[0m"
    assert strip_color_codes(text) == 'error'

def test_compute_max_widths_strips_colors():
    data = [['1.1.1.1', 'AWS', '\x1b[31mno permission\x1b[0m']]
    widths = compute_max_widths(data)
    assert widths['Permission'] >= len('no permission') + 2
