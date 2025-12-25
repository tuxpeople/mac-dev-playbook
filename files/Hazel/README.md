# Hazel Configuration

This directory contains Hazel rules and license configuration.

## Structure

```
Hazel/
├── hazelrules/          # Hazel rule files (.hazelrules)
│   ├── Desktop.hazelrules
│   ├── Downloads.hazelrules
│   ├── Downloads-old.hazelrules
│   ├── iCloudDownloads.hazelrules
│   └── iCloudDownloads-old.hazelrules
└── license              # Hazel license file (gitignored, download from 1Password)
```

## Setup

### 1. Export Rules from Existing Mac

In Hazel app:
1. Select a folder in the sidebar
2. Right-click the folder → Export Rules
3. Save with a descriptive name
4. Copy to `files/Hazel/hazelrules/`

Or manually:
```bash
# On mac with existing Hazel setup:
cp ~/Library/Application\ Support/Hazel/*.hazelrules /path/to/repo/files/Hazel/hazelrules/
# Rename them to match folder names (Downloads.hazelrules, etc.)
```

### 2. License File (Automatic)

The Hazel license is automatically downloaded from 1Password during deployment if it doesn't already exist.

**No manual action required!** The playbook will:
1. Check if `~/Library/Application Support/Hazel/license` exists
2. If not, download from 1Password: `op://Privat/Hazel 6 license/Thomas Deutsch.hazellicense`

To disable automatic license download, set in `hazel.yml`:
```yaml
configure_hazel_license: false
```

### 3. Deploy to New Mac

```bash
# Deploy Hazel rules:
./scripts/macapply --tags post

# Or just Hazel:
./scripts/macrun hazel  # (if you add this to macrun script)
```

## Configuration

Configuration is in `inventories/group_vars/macs/hazel.yml`:

- `configure_hazel`: Enable/disable Hazel deployment
- `hazel_deploy_all_rules`: Deploy all rules or only specific ones
- `hazel_folder_mappings`: Map rule files to actual folder paths
- `hazel_preferences`: Hazel app preferences
- `hazel_helper_preferences`: Hazel Helper preferences

## Notes

- Rules are deployed with volume-specific naming (e.g., `16777225-Downloads.hazelrules`)
- The volume UUID is automatically detected during deployment
- Existing rules are backed up before deployment
- Hazel is automatically restarted after deployment
