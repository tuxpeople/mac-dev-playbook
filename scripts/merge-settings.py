#!/usr/bin/env python3
"""
Merge converted settings with existing defaults.yml, removing duplicates
"""

import yaml
from pathlib import Path

def load_yaml(file_path):
    with open(file_path, 'r') as f:
        return yaml.safe_load(f)

def main():
    # Load existing defaults.yml
    existing_file = Path('/Volumes/development/github/tuxpeople/mac-dev-playbook/inventories/group_vars/macs/defaults.yml')
    existing = load_yaml(existing_file)
    existing_settings = existing.get('defaults', [])

    # Load converted settings
    converted_file = Path('/tmp/converted-settings.yml')
    converted = load_yaml(converted_file)
    converted_settings = converted.get('defaults', [])

    # Create set of existing (domain, key) pairs
    existing_keys = {(s['domain'], s['key']) for s in existing_settings}

    # Find new settings (not in existing)
    new_settings = []
    duplicate_count = 0

    for setting in converted_settings:
        key = (setting['domain'], setting['key'])
        if key not in existing_keys:
            new_settings.append(setting)
        else:
            duplicate_count += 1

    print(f"Existing settings: {len(existing_settings)}")
    print(f"Converted settings: {len(converted_settings)}")
    print(f"Duplicates found: {duplicate_count}")
    print(f"New settings to add: {len(new_settings)}")
    print()

    # Write merged settings
    merged = {
        'defaults': existing_settings + new_settings
    }

    output_file = Path('/tmp/defaults-merged.yml')
    with open(output_file, 'w') as f:
        # Write header comment
        f.write("---\n")
        f.write("# macOS defaults settings\n")
        f.write("# Settings migrated from .macos script on 2025-12-24\n")
        f.write("\n")
        yaml.dump(merged, f, default_flow_style=False, sort_keys=False, allow_unicode=True)

    print(f"Merged settings written to: {output_file}")
    print(f"Total settings in merged file: {len(merged['defaults'])}")

    # Also print counts by domain
    from collections import Counter
    domain_counts = Counter(s['domain'] for s in merged['defaults'])
    print("\nSettings by domain:")
    for domain, count in sorted(domain_counts.items(), key=lambda x: -x[1]):
        print(f"  {domain}: {count}")

if __name__ == '__main__':
    main()
