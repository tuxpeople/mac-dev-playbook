# Dependency Update Strategy

**Created**: 2025-10-23
**Status**: Active

---

## Overview

This document defines the strategy for keeping dependencies up-to-date in the mac-dev-playbook repository.

---

## 🤖 Automated Updates (Renovate)

**Status**: ✅ Renovate is active on this repository

Renovate automatically handles updates for:

- Python packages in `requirements.txt`
- Ansible roles and collections in `requirements.yml`

### Renovate Configuration

Review PRs created by Renovate:

- **Patch updates** (e.g., 1.2.3 → 1.2.4): Auto-merge if tests pass
- **Minor updates** (e.g., 1.2.x → 1.3.0): Review and merge within 1 week
- **Major updates** (e.g., 1.x → 2.0): Test thoroughly before merging

**Important**: Never auto-merge Ansible major version upgrades (e.g., 10.x → 12.x)

---

## 🐍 Python Version Strategy

### Current Version

- **Python 3.11.8** (defined in `scripts/macupdate`)
- Released: April 2023
- End of Life: October 2027

### Update Schedule

| Update Type | Frequency | Example | Action |
|-------------|-----------|---------|--------|
| **Patch** | Quarterly | 3.11.8 → 3.11.9 | Update in macupdate script |
| **Minor** | Yearly | 3.11 → 3.12 | Test for 2-3 months first |
| **Major** | As needed | 3.x → 4.x | Only when required |

### Update Process

1. **Check for new Python versions**:

   ```bash
   pyenv install --list | grep "^  3\."
   ```

2. **Test new version locally**:

   ```bash
   pyenv install 3.12.8
   pyenv virtualenv 3.12.8 test-env
   pyenv activate test-env
   pip install -r requirements.txt
   ansible-playbook plays/update.yml --check
   ```

3. **Update if successful**:
   - Edit `scripts/macupdate` line 28: `PYTHON_VERSION="3.12.8"`
   - Commit with descriptive message
   - Update all Macs

### Recommended Upgrade Path (2025)

```
Current: 3.11.8 (April 2023)
    ↓
Q2 2025: 3.12.9 (when released)
    ↓
Q4 2025: 3.13.x (after 6+ months stability)
```

**Rationale**:

- Skip 3.13.x for now (too new, released Dec 2024)
- Move to 3.12.x first (mature, stable)
- Avoid Python EOL issues (3.11 EOL: Oct 2027)

---

## 📦 requirements.txt Strategy

### Current Pinning Philosophy

**Pinned exact versions** (e.g., `ansible==10.2.0`)

**Pros**:

- Reproducible builds
- No surprise breakage
- Easy rollback

**Cons**:

- Manual updates needed (handled by Renovate)
- May miss security patches

### Version Constraints

We use **exact pinning** (`==`) for all dependencies because:

1. Renovate handles updates automatically
2. Ensures consistent behavior across all Macs
3. Easier to track what changed when issues occur

**Do NOT use**:

- `>=` (too permissive)
- `~=` (allows patch updates, but Renovate is better)

---

## 🔧 requirements.yml Strategy

Ansible roles and collections follow similar rules:

```yaml
# GOOD - Exact version
- name: geerlingguy.mac
  version: 4.0.1

# BAD - No version constraint
- name: geerlingguy.mac
```

**Update Frequency**:

- Check Renovate PRs weekly
- Test collection updates in non-production first
- Merge after successful test runs

---

## 🗓️ Manual Review Schedule

### Quarterly Review (Every 3 months)

- [ ] Review all open Renovate PRs
- [ ] Check Python version for security updates
- [ ] Update Python patch version if available
- [ ] Test all updates on non-production Mac

### Annual Review (Once per year)

- [ ] Consider Python minor version upgrade (3.11 → 3.12)
- [ ] Review Ansible major version (if Renovate suggests)
- [ ] Update this strategy document if process changed

---

## 🚨 Security Updates

**Immediate action required** for:

- CVEs in cryptography, paramiko, ansible
- Python security releases
- Critical Homebrew package vulnerabilities

**Process**:

1. Renovate usually creates PR within 24h of release
2. Review CVE details
3. Test on non-production Mac
4. Merge and deploy to all Macs within 48h

---

## 📝 Testing New Versions

### Test Checklist

Before upgrading Python or Ansible major versions:

```bash
# 1. Create test virtualenv
pyenv virtualenv <NEW_VERSION> test-mac-dev-playbook
pyenv activate test-mac-dev-playbook

# 2. Install requirements
pip install -r requirements.txt
ansible-galaxy install -r requirements.yml

# 3. Dry run
ansible-playbook plays/update.yml -i inventories -l $(hostname) --check --diff

# 4. Real run on non-production Mac
ansible-playbook plays/update.yml -i inventories -l test-mac --connection=local

# 5. Verify functionality
# - Homebrew updates work
# - Dotfiles sync works
# - SSH/GPG tasks work
# - No deprecation warnings
```

---

## 🎯 Current Action Items

### Immediate (Next Run)

- [x] cryptography upgraded to 46.0.3
- [x] paramiko upgraded to 4.0.0
- [x] pyenv virtualenv-init error fixed

### Q1 2025

- [ ] Review Renovate PRs weekly
- [ ] Consider Python 3.11.8 → 3.11.9 (when released)

### Q2 2025

- [ ] Plan Python 3.12.x migration
- [ ] Test Ansible 12.x compatibility

---

## 📚 Resources

- [Python Release Schedule](https://peps.python.org/pep-0693/)
- [Ansible Changelog](https://github.com/ansible/ansible/blob/devel/changelogs/CHANGELOG-v12.rst)
- [pyenv Versions](https://github.com/pyenv/pyenv/blob/master/plugins/python-build/share/python-build/)
- [Renovate Docs](https://docs.renovatebot.com/)

---

**Last Updated**: 2025-10-23
**Next Review**: 2025-04-23 (Quarterly)
