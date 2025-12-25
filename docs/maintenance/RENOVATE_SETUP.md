# Renovate Auto-Merge Setup

**Created**: 2025-10-23
**Status**: Active

---

## Overview

This repository uses **Renovate** to automatically manage dependency updates with intelligent auto-merge rules.

---

## 🤖 What Gets Auto-Merged?

Renovate will **automatically merge** PRs when:

1. ✅ **CI tests pass** (requirements-check + lint + integration)
2. ✅ **Update type matches rules** (see below)

### Auto-Merge Rules

| Dependency Type | Patch (x.x.X) | Minor (x.X.0) | Major (X.0.0) |
|----------------|---------------|---------------|---------------|
| **Python packages** (bcrypt, pyparsing, etc.) | ✅ Auto | ✅ Auto | ⚠️ Manual |
| **Security packages** (cryptography, paramiko) | ✅ Auto | ✅ Auto | ⚠️ Manual |
| **Ansible** | ❌ Manual | ❌ Manual | ❌ Manual |
| **Ansible roles/collections** | ❌ Manual | ❌ Manual | ❌ Manual |
| **GitHub Actions** | ✅ Auto | ✅ Auto | ⚠️ Manual |

---

## 📋 CI Testing Pipeline

Every Renovate PR triggers these tests:

### 1. **Lint Job**

- yamllint (YAML syntax)
- ansible-lint (Playbook best practices)
- shellcheck (Shell script validation)

### 2. **Requirements Check** (NEW!)

- Install all packages from requirements.txt
- Verify no dependency conflicts (`pip check`)
- Test Ansible can be imported
- Run security vulnerability scan (`safety`)
- Verify ansible-playbook executable works

### 3. **Integration Test**

- Run full playbook on macOS 11 & 12
- Syntax check
- Full execution test
- Idempotence check (no changes on 2nd run)

**If ANY test fails → PR is NOT auto-merged**

---

## ⚙️ How It Works

### Patch Updates (e.g., 1.2.3 → 1.2.4)

**Example**: `cryptography==46.0.3 → 46.0.4`

1. Renovate detects new version Monday before 6am (Europe/Zurich)
2. Creates PR with label `dependencies`
3. GitHub Actions runs CI pipeline
4. If all tests pass → **Auto-merged**
5. Next `macupdate` run installs new version

**Timeline**: Detected → Merged within ~15 minutes

---

### Minor Updates (Low-Risk Packages)

**Example**: `bcrypt==4.2.0 → 4.3.0`

**Auto-merged packages**:

- bcrypt (password hashing)
- pyparsing (parsing library)
- jmespath (JSON query)
- pexpect (process automation)

**Why auto-merge?**

- Stable APIs
- Rare breaking changes
- Low impact on Ansible

---

### Minor Updates (Security Packages)

**Example**: `paramiko==4.0.0 → 4.1.0`

**Auto-merged packages**:

- cryptography (TLS/SSL)
- paramiko (SSH library)

**Why auto-merge minor, not major?**

- Minor: Usually new features + bug fixes
- Major: API changes, deprecations
- Security patches: Often in minor releases

---

### Ansible Updates (NEVER Auto-Merge)

**Example**: `ansible==10.2.0 → 12.1.0`

**Labels**: `ansible-update`, `needs-testing`

**Why manual?**

- High risk of breaking changes
- Playbook syntax changes
- Module deprecations
- Requires thorough testing

**Process**:

1. Renovate creates PR
2. Review changelog
3. Test on non-production Mac
4. Manually merge when safe

---

## 🚨 Security Vulnerabilities

**Labels**: `security`, `priority`

**Behavior**: ❌ **NOT auto-merged** (even patches!)

**Why?**

- Requires human review of CVE details
- May need additional changes beyond version bump
- Security fixes should be tested immediately

**Process**:

1. Renovate creates PR with `security` label
2. Review CVE details in PR description
3. Test on non-production Mac (fast track)
4. Merge within 48h if safe

---

## 📅 Schedule

**Renovate runs**: Every Monday before 6am (Europe/Zurich)

**Why Monday morning?**

- Updates available at start of week
- Time to test before weekend
- Matches your workflow

**Concurrent PRs**: Max 3 at a time (prevents spam)

---

## 🔍 Monitoring Renovate

### Check Renovate Dashboard

**GitHub**: Settings → Integrations → Renovate

Shows:

- Pending updates
- Failed runs
- Rate limits
- Config validation

### Review PRs

**Filter PRs**: `label:dependencies`

**PR Format**:

```
deps: update cryptography to v46.0.4

- Updates cryptography from 46.0.3 to 46.0.4
- Release notes: [link]
- Changelog: [link]
```

---

## ⚡ Enabling Auto-Merge (GitHub Settings)

**IMPORTANT**: Enable auto-merge in repository settings:

1. Go to **Settings** → **General**
2. Scroll to **Pull Requests**
3. ✅ Enable: **Allow auto-merge**
4. ✅ Enable: **Require status checks to pass before merging**
5. Add required checks:
   - `lint`
   - `requirements-check` ← NEW!
   - `integration (macos-11)`
   - `integration (macos-12)`

Without this, `platformAutomerge: true` won't work!

---

## 🛠️ Troubleshooting

### Auto-Merge Not Working

**Check**:

1. GitHub auto-merge enabled? (see above)
2. All CI tests passing?
3. Branch protection rules configured?
4. Renovate has write permissions?

**Debug**:

```bash
# Check Renovate logs in PR description
# Look for: "Automerge: Enabled"
```

### CI Tests Failing

**Common issues**:

1. **pip check fails**: Dependency conflict
   - Review requirements.txt
   - Pin conflicting package
2. **safety check fails**: Security vulnerability
   - Review CVE details
   - Update manually if auto-merge blocked
3. **ansible-lint fails**: Syntax error in roles
   - Fix playbook issues first

### Too Many PRs

**Reduce noise**:

```json
// In renovate.json
"prConcurrentLimit": 1,  // Only 1 PR at a time
"schedule": ["on the first day of the month"]  // Monthly instead of weekly
```

---

## 📝 Example Workflow

### Week 1: Patch Updates Auto-Merge

**Monday 5:30 AM**:

```
Renovate detects:
- cryptography 46.0.3 → 46.0.4 (patch)
- bcrypt 4.2.0 → 4.2.1 (patch)
```

**Monday 5:45 AM**:

```
- Creates 2 PRs
- CI runs on both
- Both pass
- Auto-merged
```

**Monday 8:00 AM** (Next macupdate run):

```
./scripts/macupdate
→ Pulls latest master
→ Installs new versions
→ Done!
```

**Your action**: ✅ None! (Just review merged PRs later)

---

### Week 2: Ansible Update (Manual)

**Monday 5:30 AM**:

```
Renovate detects:
- ansible 10.2.0 → 12.1.0 (major)
```

**Monday 5:45 AM**:

```
- Creates PR with labels: ansible-update, needs-testing
- CI runs
- PR stays open (not auto-merged)
```

**Your action**:

1. Review changelog: <https://github.com/ansible/ansible/blob/devel/changelogs/CHANGELOG-v12.rst>
2. Test on non-production Mac:

   ```bash
   git fetch origin pull/XXX/head:renovate-test
   git checkout renovate-test
   pip install -r requirements.txt
   ansible-playbook plays/update.yml --check
   ```

3. If OK: Merge manually
4. If issues: Add comment, close PR, pin version

---

## 🎯 Benefits

✅ **Time Saved**: No manual dependency checking
✅ **Security**: Fast security patch deployment
✅ **Reliability**: CI testing before merge
✅ **Consistency**: All Macs get updates automatically
✅ **Audit Trail**: PR history shows what changed when

---

## 📚 Resources

- [Renovate Docs](https://docs.renovatebot.com/)
- [Auto-merge Configuration](https://docs.renovatebot.com/configuration-options/#automerge)
- [Package Rules](https://docs.renovatebot.com/configuration-options/#packagerules)
- [GitHub Auto-merge](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/incorporating-changes-from-a-pull-request/automatically-merging-a-pull-request)

---

## 🔧 Configuration Files

- **renovate.json**: Renovate rules and auto-merge logic
- **.github/workflows/ci.yml**: CI pipeline with requirements-check
- **requirements.txt**: Pinned Python dependencies
- **requirements.yml**: Ansible roles/collections

---

**Last Updated**: 2025-10-23
**Next Review**: After first auto-merge (check if working)
