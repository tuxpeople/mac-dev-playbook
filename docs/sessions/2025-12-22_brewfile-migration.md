---
# Session: Brewfile Migration

**Date**: 2025-12-22
**Focus**: Move Brewfiles from dotfiles repo to Ansible repo
**Status**: ✅ Completed
**Related**: REPOSITORY_REVIEW.md Priority 2, TODO.md:23-33

---

## Summary

Successfully moved Brewfiles from the dotfiles repository to the mac-dev-playbook repository, completing Phase 1 of the dotfiles/Ansible separation.

## Changes Made

### 1. File Structure

**Before**:

```
~/development/github/tuxpeople/dotfiles/
  machine/
    ├─ business_mac/
    │  └─ Brewfile
    └─ private_mac/
       └─ Brewfile

~/development/github/tuxpeople/mac-dev-playbook/
  inventories/
    group_vars/
      ├─ business_mac/
      │  └─ brew.yml → points to dotfiles repo
      └─ private_mac/
         └─ brew.yml → points to dotfiles repo
```

**After**:

```
~/development/github/tuxpeople/mac-dev-playbook/
  files/
    brewfile/
      ├─ business_mac/
      │  └─ Brewfile
      └─ private_mac/
         └─ Brewfile
  inventories/
    group_vars/
      ├─ business_mac/
      │  └─ brew.yml → points to files/brewfile/business_mac
      └─ private_mac/
         └─ brew.yml → points to files/brewfile/private_mac
```

### 2. Configuration Updates

**inventories/group_vars/business_mac/brew.yml**:

```yaml
# OLD:
homebrew_brewfile_dir: "{{dotfiles_repo_local_destination}}/machine/business_mac/"

# NEW:
homebrew_brewfile_dir: "{{ playbook_dir }}/files/brewfile/business_mac"
```

**inventories/group_vars/private_mac/brew.yml**:

```yaml
# OLD:
homebrew_brewfile_dir: "{{dotfiles_repo_local_destination}}/machine/private_mac/"

# NEW:
homebrew_brewfile_dir: "{{ playbook_dir }}/files/brewfile/private_mac"
```

### 3. Bug Fixes

**plays/full.yml** - Fixed vars syntax error:

```yaml
# WRONG (was list, should be dict):
vars:
  - homebrew_use_brewfile: true

# CORRECT:
vars:
  homebrew_use_brewfile: true
```

## Issues Encountered & Solutions

### Issue 1: YAML Syntax Error in plays/full.yml

**Error**: `Vars in a Play must be specified as a dictionary`

**Cause**: Line 8 had `- homebrew_use_brewfile: true` (list syntax) instead of dictionary syntax

**Solution**: Removed the `-` prefix

### Issue 2: YAML Parsing Failed

**Error**: `Did not find expected <document start>`

**Cause**: Added `---` document start marker to group_vars files (not needed for var files)

**Solution**: Removed `---` from brew.yml files

### Issue 3: Ansible Tries to Parse Brewfiles as YAML

**Error**: `YAML parsing failed` when Brewfiles were in `group_vars/`

**Root Cause**: Ansible automatically parses ALL files in `group_vars/<group>/` as YAML variable files. Brewfiles are Ruby DSL, not YAML!

**Solution**: Moved Brewfiles from `group_vars/` to `files/brewfile/`

**Key Learning**:

- `group_vars/` is ONLY for YAML variable files
- Non-YAML files (Brewfiles, scripts, etc.) must go in `files/` or elsewhere
- This is why the original location in dotfiles repo worked (wasn't in group_vars)

## Testing

### Dry Run Test

```bash
./scripts/macapply --tags homebrew --check --diff
```

**Result**: ✅ Success

```
PLAY [all] *************************************************
TASK [Install Homebrew packages] **************************
included: geerlingguy.mac.homebrew for UMB-L3VWMGM77F

PLAY RECAP *************************************************
UMB-L3VWMGM77F: ok=1 changed=0 unreachable=0 failed=0
```

### Production Run

```bash
./scripts/macapply --tags homebrew
```

**Status**: Ready to run (user to execute)

## Benefits Achieved

1. **Single Repository**: All Mac configuration in one place
2. **Clearer Ownership**: Brewfiles managed where they're used (Ansible)
3. **Easier Workflow**: Edit and apply in same repo
4. **Better Structure**: Files organized by purpose (files/ vs group_vars/)
5. **Solved TODO**: Closes TODO.md:23-33 Phase 1

## Next Steps

### Immediate (User Action Required)

1. **Test the migration** (if not done yet):

   ```bash
   ./scripts/macapply --tags homebrew
   ```

2. **Clean up dotfiles repo**:

   ```bash
   cd ~/development/github/tuxpeople/dotfiles
   git rm machine/business_mac/Brewfile
   git rm machine/private_mac/Brewfile
   git commit -m "Remove Brewfiles (moved to mac-dev-playbook)"
   git push
   ```

3. **Commit changes in mac-dev-playbook**:

   ```bash
   cd ~/development/github/tuxpeople/mac-dev-playbook
   git add files/brewfile/
   git add inventories/group_vars/*/brew.yml
   git add plays/full.yml
   git add docs/BREWFILE_MIGRATION.md
   git add docs/TODO.md
   git add docs/sessions/2025-12-22_brewfile-migration.md
   git commit -m "Move Brewfiles from dotfiles to Ansible repo"
   git push
   ```

### Future (From TODO.md)

**Phase 2**: Convert `.macos` script to Ansible tasks

- 952 lines of shell script
- Should become `community.general.osx_defaults` tasks
- Makes macOS settings more transparent and manageable

**Phase 3**: Clean up dotfiles repo

- Remove duplicates
- Keep only true dotfiles (shell, git, vim configs)

## Files Created/Modified

### New Files

- `files/brewfile/business_mac/Brewfile` (19KB)
- `files/brewfile/private_mac/Brewfile` (17KB)
- `docs/BREWFILE_MIGRATION.md` (migration guide)
- `docs/sessions/2025-12-22_brewfile-migration.md` (this file)

### Modified Files

- `inventories/group_vars/business_mac/brew.yml` (updated path)
- `inventories/group_vars/private_mac/brew.yml` (updated path)
- `plays/full.yml` (fixed vars syntax)
- `docs/TODO.md` (marked Phase 1 as completed)

### Files to be Deleted (in dotfiles repo)

- `machine/business_mac/Brewfile` (after verification)
- `machine/private_mac/Brewfile` (after verification)

## New Workflow Example

**Before** (two repos):

```bash
# Edit Brewfile in dotfiles repo
vim ~/development/github/tuxpeople/dotfiles/machine/business_mac/Brewfile

# Switch to Ansible repo and apply
cd ~/development/github/tuxpeople/mac-dev-playbook
macapply --tags homebrew
```

**After** (single repo):

```bash
# Edit and apply in same repo
cd ~/development/github/tuxpeople/mac-dev-playbook
vim files/brewfile/business_mac/Brewfile
macapply --tags homebrew
```

Much simpler! 🎉

## Lessons Learned

1. **Ansible group_vars is strict**: Only YAML files, everything else breaks
2. **Document start markers matter**: group_vars files don't need `---`
3. **YAML syntax is picky**: Lists vs dictionaries (vars must be dict)
4. **Testing is crucial**: `--check --diff` caught issues before production
5. **File organization matters**: Proper separation prevents parsing issues

## Related Documentation

- [BREWFILE_MIGRATION.md](../BREWFILE_MIGRATION.md) - Detailed migration guide
- [REPOSITORY_REVIEW.md](../analysis/REPOSITORY_REVIEW.md) - See Priority 2
- [WORKFLOWS.md](../WORKFLOWS.md) - Using macapply
- [TODO.md](../TODO.md) - Phase 1 now marked complete

---

**Session End**: 2025-12-22
**Time Spent**: ~30 minutes (including debugging)
**Status**: ✅ Phase 1 Complete, Ready for Cleanup
**Next Priority**: README.md updates (TODO.md:34)
