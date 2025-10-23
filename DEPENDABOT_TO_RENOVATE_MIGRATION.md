# Migration: Dependabot → Renovate

**Date**: 2025-10-23
**Reason**: Avoid conflicts, better auto-merge rules, Ansible Galaxy support

---

## Problem Identified

**Dependabot** and **Renovate** were both active on this repository:
- Both tried to manage Python packages (requirements.txt)
- Both tried to manage GitHub Actions
- They blocked each other from creating PRs
- **Last Dependabot PR**: February 2025 (cryptography 43→44)
- **Since then**: No updates from either tool

**Evidence**:
```bash
gh pr list --state all --label dependencies --limit 5
# Shows only Dependabot PRs, no Renovate PRs
```

---

## Solution: Disable Dependabot for Python + GitHub Actions

**Changed `.github/dependabot.yml`**:
- ❌ Removed: `package-ecosystem: pip`
- ❌ Removed: `package-ecosystem: github-actions`
- ✅ Kept: `package-ecosystem: docker` (if needed)
- ✅ Kept: `package-ecosystem: bundler` (if needed)

**Reason**: Renovate has superior features for this repo:
- Auto-merge with granular rules
- Ansible Galaxy support (`requirements.yml`)
- Dependency dashboard
- Better commit messages

---

## What Happens Next?

### Immediate (After Merge)

**Renovate will detect outdated dependencies**:
```
Current (outdated):
- cryptography==44.0.1  → 46.0.3 available
- paramiko==3.4.0       → 4.0.0 available
- ansible==10.2.0       → 12.1.0 available
```

**Renovate will create PRs**:
1. One PR per dependency (or grouped by config)
2. Labels: `dependencies`
3. CI runs automatically
4. Auto-merge if configured + tests pass

### Timeline

**Monday before 6am** (next scheduled run):
- Renovate scans requirements.txt
- Creates PRs for all outdated packages
- Expect 3-5 PRs initially

**First Week**:
- **Patch updates**: Auto-merged (e.g., cryptography 44.0.1 → 44.0.3)
- **Minor updates**: Auto-merged for safe packages
- **Major updates**: Manual review (Ansible 10→12)

---

## Migration Checklist

### Pre-Migration (Done)
- [x] Created renovate.json with auto-merge rules
- [x] Added requirements-check CI job
- [x] Documented in RENOVATE_SETUP.md
- [x] Disabled Dependabot for pip + github-actions

### Post-Migration (Required)

- [ ] **Enable GitHub auto-merge** in Settings:
  ```
  Settings → General → Pull Requests
  ✅ Allow auto-merge
  ✅ Require status checks before merging
  ```

- [ ] **Add required checks**:
  - `lint`
  - `requirements-check`
  - `integration (macos-11)`
  - `integration (macos-12)`

- [ ] **Monitor first Renovate run**:
  - Check PRs created (Monday before 6am)
  - Verify CI runs on PRs
  - Test auto-merge works

- [ ] **Manually update to latest** (optional, to catch up):
  ```bash
  # Update to versions we manually installed
  # (Already in requirements.txt from commit 6af2974)
  pip install -r requirements.txt
  ```

### Verification (After First Run)

- [ ] Check Renovate created PRs
- [ ] Verify at least 1 PR was auto-merged
- [ ] Confirm Dependabot didn't create conflicting PRs
- [ ] Review Renovate Dashboard for issues

---

## Expected First Run PRs

Based on current requirements.txt:

| Package | Current | Latest | Update Type | Auto-Merge? |
|---------|---------|--------|-------------|-------------|
| ansible | 10.2.0 | 12.1.0 | Major | ❌ Manual |
| cryptography | 46.0.3 | 46.0.3 | - | ✅ Up-to-date |
| paramiko | 4.0.0 | 4.0.0 | - | ✅ Up-to-date |
| bcrypt | 4.2.0 | 4.2.1? | Patch | ✅ Auto |
| pyparsing | 3.1.2 | 3.2.0? | Minor | ✅ Auto |

**Note**: cryptography and paramiko were manually updated in commit `6af2974`, so Renovate won't create PRs for these.

---

## Rollback (If Needed)

If Renovate causes issues:

1. **Re-enable Dependabot**:
   ```bash
   git revert <this-commit>
   ```

2. **Disable Renovate**:
   ```bash
   # In renovate.json:
   "enabled": false
   ```

3. **Close all Renovate PRs**:
   ```bash
   gh pr list --label dependencies --json number --jq '.[].number' | \
   xargs -I {} gh pr close {}
   ```

---

## Monitoring Renovate

### Dependency Dashboard

GitHub Issues tab should have:
- **"Dependency Dashboard"** issue (auto-created by Renovate)
- Shows all pending updates
- Lists any errors/warnings

### Check Renovate Logs

In each Renovate PR:
- Check PR description for details
- Look for "Automerge: Enabled" or "Automerge: Disabled"
- Review changelog/release notes links

### Weekly Review

Every Monday (after 6am):
- Check new Renovate PRs
- Review any manual-review-required PRs (Ansible, major versions)
- Verify auto-merged PRs didn't break anything

---

## Benefits of Migration

### Before (Dependabot)
- ❌ No auto-merge for Python packages
- ❌ No Ansible Galaxy support
- ❌ All PRs require manual merge
- ❌ Stopped working (conflict with Renovate)

### After (Renovate)
- ✅ Auto-merge patch updates (~15 min)
- ✅ Auto-merge safe minor updates
- ✅ Manages Ansible roles/collections
- ✅ Dependency dashboard
- ✅ Better conflict resolution
- ✅ Granular rules per package

---

## Troubleshooting

### Renovate Not Creating PRs

**Check**:
1. Is Renovate installed on the repo?
   - GitHub Settings → Integrations → Renovate
2. Is renovate.json valid?
   - Check for syntax errors
   - Validate at: https://docs.renovatebot.com/config-validation
3. Are dependencies outdated?
   - Check manually: `pip list --outdated`

**Force Renovate to run**:
- Close and reopen Dependency Dashboard issue
- Wait for next scheduled run (Monday 6am)
- Or: Push a commit (triggers Renovate check)

### Auto-Merge Not Working

**Check**:
1. GitHub auto-merge enabled? (Settings)
2. Required checks configured?
3. All CI tests passing?
4. Branch protection rules allow auto-merge?

**Debug**:
- Check Renovate PR description
- Look for "Automerge: Disabled" message
- Review CI test results

---

## References

- [Renovate Config](renovate.json)
- [Renovate Setup Guide](RENOVATE_SETUP.md)
- [Dependency Strategy](DEPENDENCY_STRATEGY.md)
- [CI Workflow](.github/workflows/ci.yml)

---

**Migration Status**: ✅ Complete (pending GitHub settings)
**Next Review**: After first Renovate run (Monday)
