---
# Brewfile Migration - Completed 2025-12-22

## What Changed

Moved Brewfiles from the dotfiles repository to the mac-dev-playbook repository.

### Before

```
~/development/github/tuxpeople/dotfiles/
  machine/
    ├─ business_mac/
    │  └─ Brewfile              ← WAS HERE
    └─ private_mac/
       └─ Brewfile              ← WAS HERE
```

### After

```
~/development/github/tuxpeople/mac-dev-playbook/
  inventories/
    group_vars/
      ├─ business_mac/
      │  ├─ brew.yml
      │  └─ Brewfile            ← NOW HERE
      └─ private_mac/
         ├─ brew.yml
         └─ Brewfile            ← NOW HERE
```

## Why This Change

**Problem**: Brewfiles are package manifests, not dotfiles
- They're only used by Ansible
- Managing them required understanding two repositories
- Unclear ownership

**Solution**: Move them to where they're used (Ansible repo)
- Single repository for Mac configuration
- Clear ownership: Ansible manages packages
- Easier to review changes (git diff shows package changes)
- Solves TODO.md:23-33

## Changes Made

### 1. Brewfiles Copied

```bash
# From dotfiles repo to mac-dev-playbook repo
cp ~/development/github/tuxpeople/dotfiles/machine/business_mac/Brewfile \
   inventories/group_vars/business_mac/Brewfile

cp ~/development/github/tuxpeople/dotfiles/machine/private_mac/Brewfile \
   inventories/group_vars/private_mac/Brewfile
```

### 2. Configuration Updated

**inventories/group_vars/business_mac/brew.yml**
```yaml
# OLD:
homebrew_brewfile_dir: "{{dotfiles_repo_local_destination}}/machine/business_mac/"

# NEW:
homebrew_brewfile_dir: "{{ playbook_dir }}/inventories/group_vars/business_mac"
```

**inventories/group_vars/private_mac/brew.yml**
```yaml
# OLD:
homebrew_brewfile_dir: "{{dotfiles_repo_local_destination}}/machine/private_mac/"

# NEW:
homebrew_brewfile_dir: "{{ playbook_dir }}/inventories/group_vars/private_mac"
```

## Testing Instructions

### Step 1: Verify Brewfiles Are There

```bash
ls -lh inventories/group_vars/business_mac/Brewfile
ls -lh inventories/group_vars/private_mac/Brewfile
```

Expected output:
```
-rw-r-----  19K inventories/group_vars/business_mac/Brewfile
-rwxr-x---  17K inventories/group_vars/private_mac/Brewfile
```

### Step 2: Test Configuration (Dry Run)

```bash
# Test on current Mac (dry run, won't change anything)
cd ~/development/github/tuxpeople/mac-dev-playbook
./scripts/macapply --tags homebrew --check --diff
```

Expected output:
- Should find Brewfile in new location
- Should show what packages would be installed/updated
- No errors about missing Brewfile

### Step 3: Apply for Real (When Ready)

```bash
# Apply Homebrew configuration
./scripts/macapply --tags homebrew
```

Expected output:
- Brewfile is processed from new location
- Packages are installed/updated as defined in Brewfile
- No errors

### Step 4: Verify It Works

```bash
# Check that packages from Brewfile are installed
brew list | head -n 10
brew list --cask | head -n 10
```

## Cleanup (After Successful Testing)

Once you've verified the new location works:

### In dotfiles repository

```bash
cd ~/development/github/tuxpeople/dotfiles

# Remove old Brewfiles
git rm machine/business_mac/Brewfile
git rm machine/private_mac/Brewfile

# Note: Keep Brewfile.lock.json in business_mac if it exists
# (It's in .gitignore anyway)

# Commit
git commit -m "Remove Brewfiles (moved to mac-dev-playbook repo)

Brewfiles are now managed in the mac-dev-playbook repository at:
- inventories/group_vars/business_mac/Brewfile
- inventories/group_vars/private_mac/Brewfile

This makes package management clearer as Ansible is the only consumer.

See: mac-dev-playbook/docs/BREWFILE_MIGRATION.md"

git push
```

### In mac-dev-playbook repository

```bash
cd ~/development/github/tuxpeople/mac-dev-playbook

# Add new Brewfiles and updated config
git add inventories/group_vars/business_mac/Brewfile
git add inventories/group_vars/business_mac/brew.yml
git add inventories/group_vars/private_mac/Brewfile
git add inventories/group_vars/private_mac/brew.yml
git add docs/BREWFILE_MIGRATION.md

# Commit
git commit -m "Move Brewfiles from dotfiles to Ansible repo

Moved Brewfiles from dotfiles repository to mac-dev-playbook repository:
- business_mac/Brewfile: 19KB
- private_mac/Brewfile: 17KB

Updated configuration in brew.yml to use new location:
  homebrew_brewfile_dir: {{ playbook_dir }}/inventories/group_vars/<group>

Benefits:
- Single repository for Mac configuration
- Clear ownership (Ansible manages packages)
- Easier package management workflow

Closes TODO.md:23-33
Implements REPOSITORY_REVIEW.md Priority 2"

git push
```

## Rollback (If Needed)

If something goes wrong, you can rollback:

```bash
# Revert config changes
cd ~/development/github/tuxpeople/mac-dev-playbook
git checkout inventories/group_vars/business_mac/brew.yml
git checkout inventories/group_vars/private_mac/brew.yml

# Remove copied Brewfiles
rm inventories/group_vars/business_mac/Brewfile
rm inventories/group_vars/private_mac/Brewfile

# The originals are still in dotfiles repo (until you delete them)
```

## Future: Adding Packages

### Before (Old Workflow)

```bash
# Had to edit file in dotfiles repo
vim ~/development/github/tuxpeople/dotfiles/machine/business_mac/Brewfile

# Then run Ansible from mac-dev-playbook repo
cd ~/development/github/tuxpeople/mac-dev-playbook
macapply --tags homebrew
```

### After (New Workflow)

```bash
# Edit file in mac-dev-playbook repo
vim ~/development/github/tuxpeople/mac-dev-playbook/inventories/group_vars/business_mac/Brewfile

# Apply changes (same directory)
macapply --tags homebrew
```

Much simpler!

## Notes

- **Brewfile.lock.json**: Still exists in dotfiles repo (business_mac/)
  - This is auto-generated by Homebrew
  - It's in .gitignore
  - You can delete it if you want, it will be regenerated

- **File Permissions**:
  - business_mac: `-rw-r-----` (normal file)
  - private_mac: `-rwxr-x---` (executable bit set, doesn't matter for Brewfile)

- **File Sizes**:
  - business_mac: ~19KB (larger, probably more packages)
  - private_mac: ~17KB

## Related Documentation

- [REPOSITORY_REVIEW.md](analysis/REPOSITORY_REVIEW.md) - See Priority 2
- [WORKFLOWS.md](WORKFLOWS.md) - How to use macapply
- [TODO.md](TODO.md) - Original task was at line 23-33

---

**Migration completed**: 2025-12-22
**Status**: ✅ Ready for testing
**Next**: Test with `macapply --tags homebrew --check --diff`
