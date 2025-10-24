---
# 1Password CLI Integration Strategy

**Erstellt am**: 2025-10-24
**Zweck**: Sichere Token-Verwaltung mit 1Password CLI neben Ansible Vault

---

## 🎯 Strategie: Zwei-Stufen-Ansatz

### Phase 1: Bootstrap (Ansible Vault)
**Wann**: Initial provisioning, bevor 1Password installiert/konfiguriert ist
**Was**: `inventories/group_vars/macs/secrets.yml` (Ansible Vault encrypted)

```yaml
# Beispiel (encrypted):
github_bootstrap_token: "ghp_..."  # Für init.sh Repo-Clone
ssh_private_keys:
  - name: id_rsa
    content: "-----BEGIN..."
```

**Nutzung in Playbooks**:
```yaml
- name: Clone private repos during bootstrap
  git:
    repo: "https://{{ github_bootstrap_token }}@github.com/tuxpeople/private-repo.git"
    dest: "{{ dest }}"
```

### Phase 2: Laufender Betrieb (1Password CLI)
**Wann**: Nach Installation, für Developer-Tools
**Was**: User-Config-Files mit `op://` References

```yaml
# ~/.config/ghorg/conf.yaml
GHORG_GITHUB_TOKEN: op://Private/GitHub ghorg Token/token
```

**Nutzung**:
```bash
# Im Terminal oder via Alias
op run -- ghorg clone tuxpeople
```

---

## 📋 Setup Guide

### 1. 1Password CLI Installation (via Homebrew)

Bereits in `inventories/group_vars/macs/brew.yml`:
```yaml
homebrew_cask_apps:
  - 1password-cli
```

### 2. Token in 1Password speichern

**Option A: Via CLI**
```bash
op item create \
  --category=password \
  --title="GitHub ghorg Token" \
  --vault="Private" \
  token[password]="ghp_NEUES_TOKEN_HIER"
```

**Option B: Via 1Password App**
1. Neues Item → Password
2. Title: "GitHub ghorg Token"
3. Vault: Private
4. Field: token = ghp_...
5. Notizen: Permissions: repo (read-only for cloning)

### 3. ghorg Config Template erstellen

**Für Dotfiles Repo**: `~/.config/ghorg/conf.yaml.template`
```yaml
# ghorg configuration
# Token wird via 1Password CLI injiziert

# GitHub Configuration
GHORG_SCM_TYPE: github
GHORG_CLONE_PROTOCOL: ssh
GHORG_GITHUB_TOKEN: op://Private/GitHub ghorg Token/token

# Clone Settings
GHORG_ABSOLUTE_PATH_TO_CLONE_TO: /Users/tdeutsch/development/github
GHORG_OUTPUT_DIR: tuxpeople
GHORG_SKIP_ARCHIVED: true

# [... rest of config ...]
```

**Deployment via Ansible**:
```yaml
# tasks/post/developer-tools.yml
- name: Deploy ghorg config template
  ansible.builtin.copy:
    src: "{{ dotfiles_repo_local_destination }}/.config/ghorg/conf.yaml.template"
    dest: "{{ myhomedir }}/.config/ghorg/conf.yaml"
    mode: '0600'
```

### 4. Convenience Aliases

**In `~/.aliases` (Dotfiles Repo)**:
```bash
# 1Password wrapped commands
alias ghorg='op run -- ghorg'
alias gh-with-token='op run -- gh'

# Oder generisch:
oprun() {
  op run -- "$@"
}
```

---

## 🔐 Welche Secrets gehören wohin?

### ✅ Ansible Vault (secrets.yml)
**Regel**: Alles was während Playbook-Runs benötigt wird

- SSH Private Keys (für git clone während provisioning)
- Bootstrap GitHub Token (für init.sh)
- API Tokens für Ansible-Module (z.B. munki)
- macOS Keychain-Passwörter (falls automatisch gesetzt)
- Zertifikate

### ✅ 1Password CLI
**Regel**: Tokens für Developer-Tools im User-Space

- GitHub Personal Access Tokens (für ghorg, gh CLI)
- Docker Hub Credentials
- NPM Tokens
- AWS/Cloud Provider Credentials
- API Keys für Development Tools

### 🚫 Nie in Git (auch nicht im Dotfiles Repo)
- Aktuelle/aktive Tokens
- Private Keys
- Passwörter

---

## 🛠️ Ansible Task für 1Password-basierte Configs

### Pattern: Config-Template mit op:// References

```yaml
---
# tasks/post/1password-configs.yml

- name: Ensure 1Password CLI is installed
  ansible.builtin.command:
    cmd: "{{ mybrewbindir }}/op --version"
  register: op_version
  changed_when: false
  failed_when: false

- name: Check if user is signed in to 1Password
  ansible.builtin.shell: "{{ mybrewbindir }}/op account list"
  register: op_accounts
  changed_when: false
  failed_when: false

- name: Deploy 1Password-integrated configs
  block:
    - name: Ensure config directories exist
      ansible.builtin.file:
        path: "{{ item }}"
        state: directory
        mode: '0700'
      loop:
        - "{{ myhomedir }}/.config/ghorg"
        - "{{ myhomedir }}/.config/gh"

    - name: Deploy ghorg config with 1Password references
      ansible.builtin.copy:
        src: "{{ dotfiles_repo_local_destination }}/.config/ghorg/conf.yaml.template"
        dest: "{{ myhomedir }}/.config/ghorg/conf.yaml"
        mode: '0600'

    - name: Deploy GitHub CLI config with 1Password references
      ansible.builtin.copy:
        src: "{{ dotfiles_repo_local_destination }}/.config/gh/hosts.yml.template"
        dest: "{{ myhomedir }}/.config/gh/hosts.yml"
        mode: '0600'

  when:
    - op_version.rc == 0
    - op_accounts.rc == 0

- name: Warn if 1Password not configured
  ansible.builtin.debug:
    msg: "⚠️  1Password CLI not configured. Run: op account add"
  when:
    - op_version.rc == 0
    - op_accounts.rc != 0
```

---

## 📚 1Password Secret Reference Syntax

### Basic Syntax
```
op://vault-name/item-name/field-name
```

### Examples
```bash
# Password field
op://Private/GitHub Token/password

# Custom field
op://Private/GitHub Token/token

# Section + Field
op://Private/AWS Credentials/access-keys/access-key-id

# Specific section
op://Work/Database/production/password
```

### In Config Files
```yaml
# YAML
api_token: op://Private/API Keys/github-token

# JSON
{"token": "op://Private/API Keys/github-token"}

# INI/TOML
token = op://Private/API Keys/github-token

# Shell
export TOKEN="op://Private/API Keys/github-token"
```

### Usage Patterns
```bash
# Single command
op run -- ghorg clone tuxpeople

# Shell session (alle env vars mit op:// werden injiziert)
op run --env-file=.env -- zsh

# Specific config
op run --config=/path/to/config.yaml -- command
```

---

## 🎯 Migration Plan: ghorg Config

### Step 1: Create Token in 1Password
```bash
# 1. Revoke old token: https://github.com/settings/tokens
# 2. Create new token with minimal permissions (repo:read)
# 3. Save in 1Password:
op item create \
  --category=password \
  --title="GitHub ghorg Token" \
  --vault="Private" \
  --tags="github,development" \
  token[password]="ghp_NEW_TOKEN_HERE" \
  notes="Read-only token for cloning GitHub repos with ghorg"
```

### Step 2: Create Template in Dotfiles Repo
```bash
cd ~/development/github/tuxpeople/dotfiles

# Create .config directory structure
mkdir -p .config/ghorg

# Copy current config as template, replace token
cp ~/.config/ghorg/conf.yaml .config/ghorg/conf.yaml.template

# Edit: Replace token line with 1Password reference
# GHORG_GITHUB_TOKEN: ghp_...
# →
# GHORG_GITHUB_TOKEN: op://Private/GitHub ghorg Token/token
```

### Step 3: Add to .gitignore
```bash
echo "# 1Password-managed configs (templates only)" >> .gitignore
echo ".config/ghorg/conf.yaml" >> .gitignore
echo ".config/gh/hosts.yml" >> .gitignore
```

### Step 4: Test
```bash
# Deploy template
cp .config/ghorg/conf.yaml.template ~/.config/ghorg/conf.yaml

# Test with 1Password CLI
op run -- ghorg clone tuxpeople --dry-run

# Add alias for convenience
echo 'alias ghorg="op run -- ghorg"' >> ~/.aliases
```

### Step 5: Cleanup
```bash
# Remove old config with plaintext token
# (Already done via template deployment)

# Verify no tokens in git history
cd ~/development/github/tuxpeople/dotfiles
git log --all --full-history --source --oneline -S 'ghp_'
# (Should return nothing if this was never committed)
```

---

## 🔄 Other Tools for 1Password Integration

### GitHub CLI (gh)
```yaml
# ~/.config/gh/hosts.yml.template
github.com:
    oauth_token: op://Private/GitHub CLI Token/token
    user: tuxpeople
    git_protocol: ssh
```

```bash
alias gh='op run -- gh'
```

### Docker Hub
```json
// ~/.docker/config.json.template
{
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "op://Private/Docker Hub/auth-token"
    }
  }
}
```

### NPM
```ini
# ~/.npmrc.template
//registry.npmjs.org/:_authToken=op://Private/NPM Token/token
```

### AWS CLI
```ini
# ~/.aws/credentials.template
[default]
aws_access_key_id = op://Private/AWS/access-key-id
aws_secret_access_key = op://Private/AWS/secret-access-key
```

---

## ⚠️ Security Best Practices

### 1. Token Permissions
**Principle of Least Privilege**: Tokens sollten minimal-notwendige Permissions haben

```
ghorg (clone only):     repo (read-only)
gh CLI (full):          repo, workflow, gist, user
docker:                 read/write packages
npm:                    read-only or publish
```

### 2. Token Rotation
```bash
# Alle 90 Tage Tokens rotieren
# 1. Neues Token generieren
# 2. In 1Password updaten (auto-synced zu allen Devices)
# 3. Altes Token revoken
```

### 3. .gitignore Hygiene
```gitignore
# 1Password managed (templates only in repo)
**/.config/*/conf.yaml
**/.config/*/hosts.yml
.aws/credentials
.npmrc
.docker/config.json

# Aber Templates erlauben:
!**/*.template
```

### 4. Ansible Vault für Bootstrap
```yaml
# secrets.yml bleibt encrypted, enthält:
# - SSH Keys (für initial git clone)
# - Bootstrap Token (limitiert, nur für Playbook)
# - Nicht die gleichen Tokens wie in 1Password
```

---

## 📊 Decision Matrix: Vault vs 1Password

| Use Case | Vault | 1Password | Warum? |
|----------|-------|-----------|--------|
| SSH Keys für git clone | ✅ | ❌ | Benötigt vor 1Password-Setup |
| Bootstrap GitHub Token | ✅ | ❌ | Benötigt vor 1Password-Setup |
| Developer GitHub Token | ❌ | ✅ | Häufige Rotation, User-Tool |
| Ansible-Module Credentials | ✅ | ❌ | Playbook-Run benötigt |
| macOS Admin Password | ✅ | ❌ | Für sudo/become |
| Docker Hub Login | ❌ | ✅ | User-Tool, häufig rotiert |
| NPM Token | ❌ | ✅ | User-Tool, project-specific |
| AWS Credentials | ❌ | ✅ | User-Tool, multi-profile |
| munki API Key | ✅ | ❌ | System-Level, Playbook-Run |

---

## 🚀 Next Steps

1. **Immediate**:
   - [ ] Revoke exposed GitHub token: https://github.com/settings/tokens
   - [ ] Create new token with minimal permissions
   - [ ] Store in 1Password via CLI or App

2. **Dotfiles Repo**:
   - [ ] Create `.config/ghorg/conf.yaml.template` with `op://` reference
   - [ ] Add `.config/ghorg/conf.yaml` to `.gitignore`
   - [ ] Test deployment and usage

3. **Ansible Integration** (Optional):
   - [ ] Create `tasks/post/1password-configs.yml`
   - [ ] Deploy config templates during provisioning
   - [ ] Add validation for 1Password CLI availability

4. **Documentation**:
   - [ ] Update README.md with 1Password setup instructions
   - [ ] Document which secrets go where (Vault vs 1Password)

---

## 📚 References

- 1Password CLI: https://developer.1password.com/docs/cli
- Secret References: https://developer.1password.com/docs/cli/secrets-reference-syntax
- Service Account (für CI/CD): https://developer.1password.com/docs/service-accounts
- Ansible + 1Password: https://developer.1password.com/docs/cli/shell-plugins/ansible

---

**Status**: Ready to implement
**Owner**: tdeutsch
**Priority**: HIGH (Security issue to resolve)
