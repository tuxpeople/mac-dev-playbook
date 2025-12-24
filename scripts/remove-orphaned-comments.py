#!/usr/bin/env python3
"""
Remove orphaned comments from .macos file
These are comments that belonged to migrated or removed settings
"""

from pathlib import Path
import re

def is_section_border(line):
    """Check if line is a section border (### ... #)"""
    stripped = line.strip()
    return stripped.startswith('###') and stripped.endswith('#')

def is_section_title(lines, idx):
    """Check if line is a section title (between two border lines)"""
    if idx < 1 or idx >= len(lines) - 1:
        return False

    current = lines[idx].strip()
    prev = lines[idx - 1].strip()
    next_line = lines[idx + 1].strip()

    # Section title pattern:
    # ###############################################################################
    # # Section Title                                                              #
    # ###############################################################################
    return (current.startswith('#') and
            current.endswith('#') and
            is_section_border(lines[idx - 1]) and
            is_section_border(lines[idx + 1]))

def is_comment(line):
    """Check if line is a regular comment (not section border, shebang, or commented command)"""
    stripped = line.strip()

    # Not a comment if doesn't start with #
    if not stripped.startswith('#'):
        return False

    # Not a comment if it's a section border
    if is_section_border(line):
        return False

    # Not a comment if it's empty comment
    if stripped == '#':
        return False

    # Not a comment if it's a shebang
    if stripped.startswith('#!'):
        return False

    # Not a comment if it's a commented-out command (starts with #sudo, #defaults, etc.)
    commented_command_patterns = [
        '#sudo', '#defaults', '#launchctl', '#killall',
        '#osascript', '#rm ', '#mv ', '#cp ', '#ln ',
        '#chmod', '#chflags', '#xattr', '#echo'
    ]
    if any(stripped.startswith(pattern) for pattern in commented_command_patterns):
        return False

    # Everything else is a comment
    return True

def is_defaults_write(line):
    """Check if line contains a defaults write command"""
    return 'defaults write' in line and not line.strip().startswith('#')

def is_other_command(line):
    """Check if line contains other commands we want to keep"""
    stripped = line.strip()
    if not stripped or stripped.startswith('#'):
        return False

    # Commands to keep
    keep_patterns = [
        'sudo', 'osascript', 'killall', 'launchctl',
        '/usr/libexec/PlistBuddy', 'chflags', 'xattr',
        'find', 'for app in', 'if [', 'fi', 'done',
        'printf', 'defaults -currentHost'
    ]

    return any(pattern in line for pattern in keep_patterns)

def should_keep_comment_block(lines, start_idx):
    """
    Check if a comment block should be kept.
    A comment block should be kept if it's IMMEDIATELY followed by an
    actual command (with at most one empty line in between).

    A comment is orphaned if:
    - It's followed by another comment (they belong to different settings)
    - It's followed by a section border
    - It's more than 1 empty line away from a command
    """
    empty_lines_count = 0

    for i in range(start_idx + 1, len(lines)):
        line = lines[i]
        stripped = line.strip()

        # Count empty lines
        if not stripped:
            empty_lines_count += 1
            # If more than 1 empty line, this comment is orphaned
            if empty_lines_count > 1:
                return False
            continue

        # If we hit a section border, this block is orphaned
        if is_section_border(line):
            return False

        # If we hit another comment, this block is orphaned
        # (each setting should have its own comment)
        if is_comment(line):
            return False

        # If we hit a defaults write or other command, keep the block
        if is_defaults_write(line) or is_other_command(line):
            return True

        # If we hit something else (like closing brace), this block is orphaned
        return False

    # End of file, orphaned
    return False

def reduce_empty_lines(lines):
    """Reduce consecutive empty lines to maximum 2"""
    result = []
    empty_count = 0

    for line in lines:
        if line.strip() == '':
            empty_count += 1
            if empty_count <= 2:
                result.append(line)
        else:
            empty_count = 0
            result.append(line)

    return result

def clean_macos_file(input_path, output_path):
    """Remove orphaned comments from .macos"""
    with open(input_path, 'r') as f:
        lines = f.readlines()

    kept_lines = []
    removed_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Always keep section borders
        if is_section_border(line):
            kept_lines.append(line)
            i += 1
            continue

        # Always keep section titles
        if is_section_title(lines, i):
            kept_lines.append(line)
            i += 1
            continue

        # Always keep non-comment lines
        if not is_comment(line):
            kept_lines.append(line)
            i += 1
            continue

        # For comment lines, check if they should be kept
        # Collect the entire comment block
        comment_block_start = i
        comment_block = [line]

        # Collect consecutive comment lines (not section borders/titles)
        j = i + 1
        while j < len(lines):
            next_line = lines[j]
            next_stripped = next_line.strip()

            # Stop at empty line or non-comment
            if not next_stripped or not is_comment(next_line):
                break

            # Stop at section border
            if is_section_border(next_line):
                break

            # Stop at section title
            if is_section_title(lines, j):
                break

            comment_block.append(next_line)
            j += 1

        # Check if this comment block should be kept
        if should_keep_comment_block(lines, j - 1):
            kept_lines.extend(comment_block)
        else:
            removed_lines.extend([(i + idx + 1, line) for idx, line in enumerate(comment_block)])

        i = j

    # Reduce consecutive empty lines
    kept_lines = reduce_empty_lines(kept_lines)

    # Write cleaned file
    with open(output_path, 'w') as f:
        f.writelines(kept_lines)

    return kept_lines, removed_lines

def main():
    input_file = Path.home() / 'development/github/tuxpeople/dotfiles/.macos'
    output_file = Path.home() / 'development/github/tuxpeople/dotfiles/.macos.cleaned'

    print("=" * 60)
    print("Removing orphaned comments from .macos")
    print("=" * 60)
    print(f"Input:  {input_file}")
    print(f"Output: {output_file}")
    print()

    kept, removed = clean_macos_file(input_file, output_file)

    print(f"Original lines: {len(kept) + len(removed)}")
    print(f"Kept lines: {len(kept)}")
    print(f"Removed comment lines: {len(removed)}")
    print()

    if removed:
        print("Sample removed comments:")
        for line_num, content in removed[:20]:
            preview = content.strip()[:70]
            print(f"  Line {line_num}: {preview}")
        if len(removed) > 20:
            print(f"  ... and {len(removed) - 20} more")

    print()
    print(f"✅ Cleaned file written to: {output_file}")
    print()
    print("To apply:")
    print(f"  mv {output_file} {input_file}")

if __name__ == '__main__':
    main()
