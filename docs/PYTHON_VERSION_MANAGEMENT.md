---
# Python Version Management

**Implemented**: 2025-12-22
**Purpose**: Centralize Python version configuration in one place

---

## Overview

The Python version used by mac-dev-playbook is now centrally managed in `.python-version` at the repository root.

## The Problem (Before)

Python version was hardcoded in multiple places:

```bash
# scripts/macupdate:5
PYTHON_VERSION="${PYTHON_VERSION:-3.11.8}"

# inventories/group_vars/macs/general.yml:26
python_versions_to_keep:
  - "3.11.8"  # Comment pointing to macupdate
```

**Issues:**

- When upgrading Python, must update multiple files
- Easy to forget a location
- Comments created circular references

## The Solution (After)

**Single Source of Truth**: `.python-version` file

```
3.11.8
```

**Benefits:**

- One file to update when changing Python version
- Standard convention (used by pyenv, asdf, etc.)
- Clear, simple, no circular references

## How It Works

### 1. .python-version File

```bash
# Repository root
.python-version
```

Contains just the version number:

```
3.11.8
```

### 2. macupdate Script

Automatically reads from `.python-version`:

```bash
# scripts/macupdate:23-30
PYTHON_VERSION_FILE="${REPO_DIR}/.python-version"
if [[ -f "${PYTHON_VERSION_FILE}" ]]; then
  PYTHON_VERSION=$(cat "${PYTHON_VERSION_FILE}" | tr -d '[:space:]')
else
  # Fallback to hardcoded version if file doesn't exist
  PYTHON_VERSION="3.11.8"
fi
```

**Features:**

- Automatically detects repository location
- Reads version from `.python-version`
- Fallback to hardcoded version if file missing
- Strips whitespace for safety

### 3. Ansible Configuration

References `.python-version` in comments:

```yaml
# inventories/group_vars/macs/general.yml:24-28
# Python version management
# Primary version is defined in .python-version file at repository root
# scripts/macupdate reads from .python-version automatically
python_versions_to_keep:
  - "3.11.8"  # Primary version (keep in sync with .python-version)
```

**Note:** Ansible can't automatically read the file (no native support), so the version is still listed but with clear documentation pointing to `.python-version`.

## Upgrading Python Version

### Old Way (Multiple Files)

```bash
# 1. Update scripts/macupdate
vim scripts/macupdate  # Change line 5

# 2. Update general.yml
vim inventories/group_vars/macs/general.yml  # Change line 26

# 3. Update comments/references
# (Hope you didn't miss anything!)
```

### New Way (Single File)

```bash
# 1. Update .python-version
echo "3.12.9" > .python-version

# 2. Update general.yml to match (manual sync needed)
vim inventories/group_vars/macs/general.yml  # Update line 28

# 3. Done!
```

**Note:** Step 2 is still manual because Ansible doesn't auto-read `.python-version`, but at least there's a clear source of truth.

## Testing

### Verify macupdate reads correctly

```bash
# Check what version macupdate will use
grep -A 8 "PYTHON_VERSION_FILE" scripts/macupdate

# Or run macupdate with dry-run (if such mode exists)
# It will log: "Python version: 3.11.8" (from .python-version)
```

### Verify .python-version is correct

```bash
cat .python-version
# Should show: 3.11.8
```

### Test version change

```bash
# Temporarily change version
echo "3.12.0" > .python-version

# Check if macupdate would use it
# (Don't actually run it unless you want to install Python 3.12!)

# Restore
echo "3.11.8" > .python-version
```

## Compatibility

### pyenv

The `.python-version` file is a standard pyenv convention:

```bash
# pyenv automatically uses .python-version
cd ~/development/github/tuxpeople/mac-dev-playbook
python --version  # Will use version from .python-version (if pyenv active)
```

### Other Tools

Many Python version managers support `.python-version`:

- pyenv ✅
- asdf ✅
- rtx/mise ✅

## Future Improvements

### Option 1: Auto-sync general.yml

Could use Ansible lookup to read `.python-version`:

```yaml
# hypothetical
python_versions_to_keep:
  - "{{ lookup('file', playbook_dir + '/.python-version') | trim }}"
```

**Pros:** Truly single source of truth
**Cons:** Adds complexity, breaks if file missing

### Option 2: Validation Task

Add an Ansible task to warn if versions don't match:

```yaml
- name: Validate Python version consistency
  assert:
    that:
      - "'3.11.8' in python_versions_to_keep"
    fail_msg: "Python version mismatch! Check .python-version"
```

## Related Files

- `.python-version` - Central version definition
- `scripts/macupdate` - Reads from .python-version
- `inventories/group_vars/macs/general.yml` - Documents the version
- `scripts/init.sh` - Uses system Python (doesn't read .python-version)
- `requirements.txt` - Python dependencies (shared across Python versions)

## Requirements.txt Strategy

**Updated**: 2025-12-25
**Challenge**: Same requirements.txt file used by both init.sh (Python 3.9) and macupdate (Python 3.11+)

### The Problem

Different Python versions support different package versions:

- Python 3.9: Can only install ansible 9.x (ansible 10+ requires Python 3.10+)
- Python 3.11+: Can install ansible 12.x or newer

But we use the same `requirements.txt` for both!

### The Solution: Flexible Version Ranges

**requirements.txt**:

```txt
ansible>=9.0
bcrypt>=4.0
cryptography>=41.0
...
```

**How it works**:

1. **init.sh** (fresh Mac with System Python 3.9):
   - Runs: `pip install --requirement requirements.txt`
   - pip sees: `ansible>=9.0`
   - pip checks: Which versions work with Python 3.9?
   - pip installs: **ansible 9.x** (latest 3.9-compatible)

2. **macupdate** (established Mac with pyenv Python 3.11+):
   - Runs: `pip install --requirement requirements.txt`
   - pip sees: `ansible>=9.0`
   - pip checks: Which versions work with Python 3.11?
   - pip installs: **ansible 12.x or newer** (latest available)

### Why This Works

pip is smart about Python version compatibility:

- Packages declare their Python requirements in metadata
- pip automatically filters out incompatible versions
- Same requirements.txt → different installations based on Python version

### Alternative Approaches (Not Used)

**Option A: Fixed versions**

```txt
ansible==9.0.0  # Too restrictive
```

- ❌ Locks everyone to old version
- ❌ No security updates

**Option B: Separate files**

```txt
requirements.txt       # For init.sh (Python 3.9)
requirements-dev.txt   # For macupdate (Python 3.11+)
```

- ❌ More maintenance
- ❌ Duplication
- ❌ Easy to forget updating both

**Option C: Upper bounds**

```txt
ansible>=9.0,<13.0  # Previously used
```

- ⚠️ Needs manual updates when new versions release
- ⚠️ May block compatible versions unnecessarily

### Current Strategy: Minimum Version Only

```txt
ansible>=9.0  # ✅ Best approach
```

**Benefits**:

- ✅ Automatic compatibility with all Python versions
- ✅ Single source of truth
- ✅ Always gets latest compatible version
- ✅ No manual upper bound updates needed
- ✅ Works for fresh setups (Python 3.9) and established setups (Python 3.11+)

### Testing Version Selection

```bash
# Python 3.9 (init.sh scenario)
/Library/Developer/CommandLineTools/usr/bin/python3 -m pip install ansible>=9.0 --dry-run
# Would install: ansible 9.x

# Python 3.11+ (macupdate scenario)
pyenv shell 3.11.8
pip install ansible>=9.0 --dry-run
# Would install: ansible 12.x or newer
```

## See Also

- [REPOSITORY_REVIEW.md](analysis/REPOSITORY_REVIEW.md) - Priority 5
- [pyenv documentation](https://github.com/pyenv/pyenv#choosing-the-python-version)
- [.python-version convention](https://github.com/pyenv/pyenv#understanding-shims)

---

**Status**: ✅ Implemented
**Priority**: 5 (Low effort, nice to have)
**Implements**: REPOSITORY_REVIEW.md Priority 5
