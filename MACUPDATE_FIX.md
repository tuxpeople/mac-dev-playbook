# macupdate Script - Required Fixes

**Location**: `~/iCloudDrive/Allgemein/bin/macupdate`

## Issue 1: pyenv virtualenv-init Error

**Symptom**:
```
pyenv: no such command `virtualenv-init'
```

**Root Cause**:
- `pyenv virtualenv-init` command was deprecated in pyenv-virtualenv 1.2.0
- The functionality is now integrated into `pyenv init -`

**Fix**:

Edit `~/iCloudDrive/Allgemein/bin/macupdate`, **Line 25**:

```bash
# BEFORE (INCORRECT):
eval "$(pyenv virtualenv-init -)"

# AFTER (FIXED):
# Comment out or remove the line entirely
# eval "$(pyenv virtualenv-init -)"
```

**Rationale**: Line 24 already contains `eval "$(pyenv init -)"` which handles virtualenv initialization.

---

## Issue 2: Paramiko TripleDES Deprecation Warnings

**Symptom**:
```
CryptographyDeprecationWarning: TripleDES has been moved to
cryptography.hazmat.decrepit.ciphers.algorithms.TripleDES
```

**Root Cause**:
- Outdated `cryptography` (44.0.1) and `paramiko` (3.4.0) versions
- TripleDES algorithm moved to deprecated module in newer cryptography versions

**Fix**: ✅ **Already applied in commit (pending)**

Updated `requirements.txt`:
- `cryptography==44.0.1` → `cryptography==46.0.3`
- `paramiko==3.4.0` → `paramiko==4.0.0`

**Apply with**:
```bash
cd ~/development/github/tuxpeople/mac-dev-playbook
pip3 install --upgrade -r requirements.txt
```

---

## Recommended Action

1. **Edit macupdate script** (manual step, not in repo):
   ```bash
   vi ~/iCloudDrive/Allgemein/bin/macupdate
   # Comment out line 25: eval "$(pyenv virtualenv-init -)"
   ```

2. **Upgrade Python packages** (will happen automatically on next macupdate run):
   - Already fixed in requirements.txt
   - Next run will install updated versions

---

**Created**: 2025-10-23
**Status**: macupdate fix requires manual edit (file in iCloud, not in repo)
