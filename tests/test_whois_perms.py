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

def test_expand_cidr_single_ip():
    assert expand_cidr('192.168.1.1') == ['192.168.1.1']

def test_expand_cidr_cidr_range():
    result = expand_cidr('10.0.0.0/30')
    assert len(result) == 4
    assert result == ['10.0.0.0', '10.0.0.1', '10.0.0.2', '10.0.0.3']
