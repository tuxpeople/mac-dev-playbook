#!/usr/bin/env python3
"""
Convert Phase 2 settings from .macos to Ansible YAML format
Phase 2: App-specific but stable settings
"""

import re
import sys
from pathlib import Path

def parse_defaults_write(line):
    """Parse a defaults write command and return dict with components"""
    line = line.strip()
    if line.startswith('#') or not line.startswith('defaults write'):
        return None

    # Split on whitespace, handling quoted strings
    parts = re.findall(r'[^\s"]+|"[^"]*"', line)

    if len(parts) < 4:
        return None

    domain = parts[2]
    key = parts[3]

    # Determine type and value
    type_flag = None
    value = None

    if len(parts) >= 6:
        type_flag = parts[4]
        value = parts[5].strip('"')
    elif len(parts) == 5:
        value = parts[4].strip('"')

    # Map defaults types to Ansible types
    ansible_type = None
    if type_flag == '-bool':
        ansible_type = 'bool'
    elif type_flag == '-int':
        ansible_type = 'int'
    elif type_flag == '-string':
        ansible_type = 'string'
    elif type_flag == '-float':
        ansible_type = 'float'
    elif type_flag == '-array':
        ansible_type = 'array'
    elif type_flag == '-dict-add':
        return None  # Complex, skip

    # Generate description from key name
    description = re.sub(r'([a-z])([A-Z])', r'\1 \2', key)
    description = description.replace('_', ' ').strip()

    return {
        'domain': domain,
        'key': key,
        'type': ansible_type,
        'value': value,
        'description': description,
        'original_line': line
    }

def convert_to_ansible_yaml(setting):
    """Convert setting dict to Ansible YAML format"""
    lines = []
    lines.append(f"  - domain: {setting['domain']}")
    lines.append(f"    key: {setting['key']}")
    lines.append(f"    name: {setting['description']}")
    if setting['type']:
        lines.append(f"    type: {setting['type']}")
    lines.append(f"    value: '{setting['value']}'")
    return '\n'.join(lines)

def main():
    macos_file = Path.home() / 'development/github/tuxpeople/dotfiles/.macos'

    if not macos_file.exists():
        print(f"Error: {macos_file} not found", file=sys.stderr)
        sys.exit(1)

    print("# Phase 2 settings from .macos")
    print("# App-specific but stable settings")
    print()
    print("phase2_settings:")

    # Phase 2 domains
    target_domains = [
        'com.apple.ActivityMonitor',
        'com.apple.TextEdit',
        'com.apple.terminal',
        'com.apple.Terminal',
        'com.apple.DiskUtility',
        'com.apple.SoftwareUpdate',
        'com.apple.TimeMachine',
    ]

    settings_count = 0

    with open(macos_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            setting = parse_defaults_write(line)
            if not setting:
                continue

            if setting['domain'] not in target_domains:
                continue

            print(convert_to_ansible_yaml(setting))
            print(f"    # Source: .macos line {line_num}")
            print()
            settings_count += 1

    print(f"\n# Total Phase 2: {settings_count} settings", file=sys.stderr)

if __name__ == '__main__':
    main()
