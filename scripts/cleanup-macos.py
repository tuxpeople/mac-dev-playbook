#!/usr/bin/env python3
"""
Clean up .macos script by removing:
1. Commented-out defaults write commands (51 lines)
2. Safari settings (24 lines - domain doesn't exist)
3. Mail settings (9 lines - domain doesn't exist)
"""

from pathlib import Path
import re

def should_keep_line(line, in_safari_section=False, in_mail_section=False):
    """Determine if a line should be kept"""
    stripped = line.strip()

    # Keep empty lines and section headers
    if not stripped or stripped.startswith('###'):
        return True

    # Remove commented-out defaults write commands
    if re.match(r'^\s*#\s*defaults write', line):
        return False

    # Remove Safari settings (domain doesn't exist)
    if 'defaults write com.apple.Safari' in line:
        return False

    # Remove Mail settings (domain doesn't exist)
    if 'defaults write com.apple.mail' in line:
        return False

    # Keep everything else
    return True

def clean_macos_file(input_path, output_path):
    """Clean .macos file and write to output"""
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
    output_file = Path.home() / 'development/github/tuxpeople/dotfiles/.macos.cleaned'

    print("Cleaning .macos script...")
    print(f"Input: {input_file}")
    print(f"Output: {output_file}")
    print()

    kept, removed = clean_macos_file(input_file, output_file)

    print(f"Original lines: {len(kept) + len(removed)}")
    print(f"Kept lines: {len(kept)}")
    print(f"Removed lines: {len(removed)}")
    print()

    # Show some removed lines as examples
    print("Examples of removed lines:")
    for line_num, content in removed[:10]:
        print(f"  Line {line_num}: {content[:80]}")
    if len(removed) > 10:
        print(f"  ... and {len(removed) - 10} more")

    print()
    print(f"✅ Cleaned file written to: {output_file}")
    print()
    print("To apply:")
    print(f"  mv {output_file} {input_file}")

if __name__ == '__main__':
    main()
