#!/usr/bin/env python3
"""
Remove all migrated settings from .macos
These settings are now in Ansible defaults.yml
"""

from pathlib import Path
import re

def should_keep_line(line):
    """Determine if a line should be kept in .macos"""
    stripped = line.strip()

    # Keep empty lines, comments (except commented defaults write), section headers
    if not stripped or stripped.startswith('###'):
        return True

    # Keep non-defaults-write lines (sudo, pmset, launchctl, etc.)
    if 'defaults write' not in line:
        return True

    # Remove if it's a defaults write for migrated domains
    migrated_domains = [
        # Phase 1 domains (High Priority - System Level)
        'NSGlobalDomain',
        'com.apple.dock',
        'com.apple.finder',
        'com.apple.screensaver',
        'com.apple.screencapture',

        # Phase 2 domains (Medium Priority - App Specific but Stable)
        'com.apple.ActivityMonitor',
        'com.apple.TextEdit',
        'com.apple.terminal',
        'com.apple.Terminal',
        'com.apple.DiskUtility',
        'com.apple.SoftwareUpdate',
        'com.apple.TimeMachine',
    ]

    for domain in migrated_domains:
        if f'defaults write {domain}' in line:
            return False

    # Keep everything else
    return True

def clean_macos_file(input_path, output_path):
    """Remove migrated settings from .macos"""
    kept_lines = []
    removed_lines = []
    line_num = 0

    with open(input_path, 'r') as f:
        for line in f:
            line_num += 1
            if should_keep_line(line):
                kept_lines.append(line)
            else:
                removed_lines.append((line_num, line.strip()))

    # Write cleaned file
    with open(output_path, 'w') as f:
        f.writelines(kept_lines)

    return kept_lines, removed_lines

def main():
    input_file = Path.home() / 'development/github/tuxpeople/dotfiles/.macos'
    output_file = Path.home() / 'development/github/tuxpeople/dotfiles/.macos.final'

    print("=" * 60)
    print("Removing migrated settings from .macos")
    print("=" * 60)
    print(f"Input:  {input_file}")
    print(f"Output: {output_file}")
    print()

    kept, removed = clean_macos_file(input_file, output_file)

    print(f"Original lines: {len(kept) + len(removed)}")
    print(f"Kept lines: {len(kept)}")
    print(f"Removed lines: {len(removed)}")
    print()

    # Group removed lines by domain
    from collections import Counter
    domains = Counter()
    for _, line in removed:
        match = re.search(r'defaults write (\S+)', line)
        if match:
            domains[match.group(1)] += 1

    print("Removed by domain:")
    for domain, count in sorted(domains.items(), key=lambda x: -x[1]):
        print(f"  {domain}: {count}")

    print()
    print("Sample removed lines:")
    for line_num, content in removed[:15]:
        print(f"  Line {line_num}: {content[:75]}")
    if len(removed) > 15:
        print(f"  ... and {len(removed) - 15} more")

    print()
    print(f"✅ Cleaned file written to: {output_file}")
    print()
    print("To apply:")
    print(f"  mv {output_file} {input_file}")

if __name__ == '__main__':
    main()
