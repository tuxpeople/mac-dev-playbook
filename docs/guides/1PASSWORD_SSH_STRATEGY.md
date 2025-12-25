# 1Password SSH Agent Integration - Strategie

**Erstellt**: 2025-10-22
**Context**: Du verwendest 1Password mit SSH Agent Support

---

## 🎯 Aktuelle Situation vs. Bessere Lösung

### Aktuell im Playbook

**Was passiert jetzt**:

```yaml
# roles/ansible-mac-update/tasks/ssh.yaml
- name: Update SSH Keys
  ansible.builtin.copy:
    src: "{{ssh_keys_src}}/"  # Von iCloudDrive
    dest: "{{myhomedir}}/.ssh/"
    remote_src: "true"
```

**Problem**:

- SSH Keys werden aus iCloud kopiert
- Keys liegen dann auf dem Filesystem
- Duplikation (iCloud + lokales Filesystem + 1Password)
- Security Risk: Keys in mehreren Locations

### Mit 1Password SSH Agent

**Was möglich ist**:

- SSH Keys nur in 1Password speichern
- 1Password SSH Agent managed die Keys
- Keine Keys auf dem Filesystem nötig
- Biometric Auth für SSH Operations

---

## 📋 Analyse: Was du brauchst

### Szenario 1: Neuer Mac (Initial Setup)

**Ohne 1Password SSH Agent**:

1. ❌ Manuell SSH Keys aus 1Password exportieren
2. ❌ Keys nach `~/.ssh/` kopieren
3. ❌ Permissions setzen
4. ❌ In SSH Agent laden

**Mit 1Password SSH Agent**:

1. ✅ 1Password installieren & einloggen
2. ✅ SSH Agent in 1Password aktivieren
3. ✅ SSH Config updaten um 1Password zu nutzen
4. ✅ **Fertig!** Keine Keys kopieren nötig

### Szenario 2: Daily Use / Updates

**Ohne 1Password SSH Agent**:

- ❌ Keys müssen synchronisiert bleiben (iCloud ↔ lokales Filesystem)
- ❌ Update Playbook kopiert Keys bei jedem Run

**Mit 1Password SSH Agent**:

- ✅ Keys nur in 1Password
- ✅ Kein Copy nötig
- ✅ Update Playbook kann SSH Key Management überspringen

---

## 🔧 Empfohlene Strategie

### Phase 1: Prüfen was du hast

```bash
# 1. Prüfe ob 1Password SSH Agent läuft:
echo $SSH_AUTH_SOCK
# Sollte zeigen: ~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock

# 2. Liste SSH Keys in 1Password:
ssh-add -l
# Sollte Keys von 1Password zeigen

# 3. Prüfe SSH Config:
cat ~/.ssh/config | grep -A 5 "IdentityAgent"
```

### Phase 2: Entscheiden welche Keys wo

Du hast vermutlich:

**SSH Keys in 1Password** (vermutlich):

- GitHub Key
- Server Keys
- Deploy Keys

**SSH Keys aktuell im Filesystem** (`~/.ssh/`):

- Möglicherweise die gleichen?
- Oder alte/redundante Keys?

**SSH Keys in iCloud** (`~/iCloudDrive/Allgemein/dotfiles/ssh_keys`):

- Backup?
- Sync zwischen Macs?

---

## 🎯 Drei Strategien zur Auswahl

### Strategie A: **Full 1Password** (EMPFOHLEN für neue Setups)

**Konzept**: Alle SSH Keys nur in 1Password, nichts auf Filesystem

**Vorteile**:

- ✅ Maximale Security (Biometric Auth)
- ✅ Keine Keys auf Disk
- ✅ Automatisches Sync zwischen Macs via 1Password
- ✅ Einfachste Lösung

**Nachteile**:

- ⚠️ Benötigt 1Password CLI für Ansible Automation
- ⚠️ Initial Setup nötig auf jedem Mac

**Ansible Changes**:

```yaml
# SSH Key Copy Task wird ÜBERSPRUNGEN
- name: Update SSH Keys
  ansible.builtin.copy:
    src: "{{ssh_keys_src}}/"
    dest: "{{myhomedir}}/.ssh/"
  when: false  # Deaktiviert - nutzen 1Password SSH Agent
```

**SSH Config**:

```ssh
# ~/.ssh/config
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    # Alle Keys kommen von 1Password
```

---

### Strategie B: **Hybrid** (Für Transition)

**Konzept**: 1Password für persönliche Keys, Filesystem für spezielle Keys

**Use Case**:

- Persönliche GitHub/GitLab Keys → 1Password
- Server Deploy Keys → Filesystem (falls rotation nötig)
- Legacy Keys → Filesystem

**Ansible Changes**:

```yaml
# Conditional SSH Key Copy
- name: Check if we should use filesystem SSH keys
  set_fact:
    use_filesystem_ssh_keys: "{{ use_1password_ssh_agent | default(true) == false }}"

- name: Update SSH Keys (only if not using 1Password)
  ansible.builtin.copy:
    src: "{{ssh_keys_src}}/"
    dest: "{{myhomedir}}/.ssh/"
    remote_src: "true"
  when: use_filesystem_ssh_keys
  no_log: true
```

**SSH Config**:

```ssh
# ~/.ssh/config
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Spezielle Hosts mit Filesystem Keys:
Host legacy-server.com
    IdentityFile ~/.ssh/id_rsa_legacy
    IdentityAgent none  # Nutze normalen SSH Agent
```

---

### Strategie C: **iCloud Backup, 1Password Primary** (BESTE BALANCE)

**Konzept**:

- 1Password SSH Agent für daily use
- iCloud hat Backup der Keys (für Notfall)
- Ansible kopiert Keys nur bei Initial Setup

**Vorteile**:

- ✅ 1Password Convenience im daily use
- ✅ iCloud Backup falls 1Password Problem
- ✅ Initial Setup automatisiert

**Ansible Changes**:

```yaml
# In group_vars:
use_1password_ssh_agent: true  # Default
initial_setup_mode: false      # Wird zu true bei fresh setup

# SSH Task:
- name: Update SSH Keys (only during initial setup)
  ansible.builtin.copy:
    src: "{{ssh_keys_src}}/"
    dest: "{{myhomedir}}/.ssh/"
    remote_src: "true"
  when:
    - not use_1password_ssh_agent or initial_setup_mode
    - ssh_keys_src_stat.stat.exists
  no_log: true
```

---

## 🛠️ Implementation für Strategie C (Empfehlung)

### 1. SSH Config Setup

**Erstelle**: `files/ssh_config_1password`

```ssh
# 1Password SSH Agent Configuration
Host *
    # Use 1Password SSH Agent
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

    # Fallback auf standard SSH agent falls 1Password nicht läuft
    # (macOS lädt automatisch keys aus ~/.ssh/ in standard agent)
    AddKeysToAgent yes
    UseKeychain yes
```

### 2. Ansible Task Updates

**Ändere** `roles/ansible-mac-update/tasks/ssh.yaml`:

```yaml
---
- name: Ensure .ssh folder exists
  file:
    path: "{{myhomedir}}/.ssh"
    state: directory
    mode: '0700'
  become: false

# SSH Config Management
- name: Check if SSH config exists
  ansible.builtin.stat:
    path: "{{myhomedir}}/.ssh/config"
  register: ssh_config_stat

- name: Backup existing SSH config
  ansible.builtin.copy:
    src: "{{myhomedir}}/.ssh/config"
    dest: "{{myhomedir}}/.ssh/config.backup.{{ ansible_date_time.epoch }}"
    remote_src: yes
    mode: '0600'
  when: ssh_config_stat.stat.exists
  become: false

- name: Find SSH config fragments
  ansible.builtin.find:
    paths: "{{ ssh_config_src }}"
    patterns: "*"
  register: ssh_config_fragments
  failed_when: false

- name: Build SSH config from fragments
  ansible.builtin.assemble:
    src: "{{ ssh_config_src }}"
    dest: "{{myhomedir}}/.ssh/config"
    mode: '0600'
  become: false
  when: ssh_config_fragments.matched > 0

- name: Add 1Password SSH Agent configuration to SSH config
  ansible.builtin.blockinfile:
    path: "{{myhomedir}}/.ssh/config"
    marker: "# {mark} 1PASSWORD SSH AGENT"
    block: |
      # 1Password SSH Agent Configuration
      Host *
          IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
          AddKeysToAgent yes
          UseKeychain yes
    create: yes
    mode: '0600'
  become: false
  when: use_1password_ssh_agent | default(true)

# SSH Keys Management
- name: Check if SSH keys source directory exists
  ansible.builtin.stat:
    path: "{{ ssh_keys_src }}"
  register: ssh_keys_src_stat

- name: Check if this is initial setup (no SSH keys present yet)
  ansible.builtin.find:
    paths: "{{myhomedir}}/.ssh"
    patterns: "id_*"
    excludes: "*.pub"
    file_type: file
  register: existing_ssh_keys

- name: Update SSH Keys (only if needed)
  ansible.builtin.copy:
    src: "{{ssh_keys_src}}/"
    dest: "{{myhomedir}}/.ssh/"
    remote_src: "true"
    mode: preserve
  become: false
  when:
    - ssh_keys_src_stat.stat.exists
    - (existing_ssh_keys.matched == 0) or (force_ssh_key_update | default(false))
  no_log: true

- name: Find SSH private keys
  ansible.builtin.find:
    paths: "{{myhomedir}}/.ssh"
    patterns: "id_*"
    excludes: "*.pub"
    file_type: file
  register: ssh_private_keys_found
  become: false

- name: Fix permissions of SSH private keys
  ansible.builtin.file:
    path: "{{ item.path }}"
    owner: "{{ ansible_user }}"
    group: staff
    mode: '0600'
  loop: "{{ ssh_private_keys_found.files }}"
  loop_control:
    label: "{{ item.path | basename }}"
  no_log: true
  when: ssh_private_keys_found.matched > 0

- name: Find SSH public keys
  ansible.builtin.find:
    paths: "{{myhomedir}}/.ssh"
    patterns: "id_*.pub"
    file_type: file
  register: ssh_public_keys_found
  become: false

- name: Fix permissions of SSH public keys
  ansible.builtin.file:
    path: "{{ item.path }}"
    owner: "{{ ansible_user }}"
    group: staff
    mode: '0644'
  loop: "{{ ssh_public_keys_found.files }}"
  loop_control:
    label: "{{ item.path | basename }}"
  when: ssh_public_keys_found.matched > 0
```

### 3. Group Vars Konfiguration

**Füge zu** `inventories/group_vars/macs/general.yml`:

```yaml
# 1Password SSH Agent Configuration
use_1password_ssh_agent: true

# Force SSH key update from iCloud (set to true for one-time sync)
force_ssh_key_update: false
```

---

## 📖 Workflow mit 1Password

### Neuer Mac Setup

```bash
# 1. Mac Setup Wizard durchlaufen
# 2. 1Password installieren (via Homebrew im Playbook)
brew install --cask 1password

# 3. 1Password einloggen & SSH Agent aktivieren
# → 1Password → Settings → Developer → SSH Agent aktivieren

# 4. Initial Playbook Run
ansible-playbook plays/full.yml -i inventories -l $(hostname) --connection=local

# 5. Verify SSH Agent
ssh-add -l
# Sollte Keys von 1Password zeigen

# 6. Test
ssh -T git@github.com
# Sollte mit 1Password Biometric Auth funktionieren
```

### Daily Updates

```bash
# Normal update run
ansible-playbook plays/update.yml -i inventories -l $(hostname) --connection=local

# SSH Keys werden NICHT kopiert (weil bereits vorhanden oder in 1Password)
# Nur SSH Config wird aktualisiert
```

### Wenn du Keys syncen willst (einmalig)

```bash
# Force SSH keys update from iCloud:
ansible-playbook plays/update.yml -i inventories -l $(hostname) --connection=local \
  -e "force_ssh_key_update=true"
```

---

## 🔍 Prüfung: Welche Keys hast du wo?

### Schritt 1: Inventory machen

```bash
echo "=== 1Password SSH Keys ==="
# 1Password app → SSH Keys section
# Oder via CLI:
op item list --categories "SSH Key" 2>/dev/null || echo "1Password CLI nicht installiert"

echo ""
echo "=== Filesystem SSH Keys (aktuell) ==="
ls -la ~/.ssh/id_* 2>/dev/null || echo "Keine Keys im Filesystem"

echo ""
echo "=== iCloud SSH Keys ==="
ls -la ~/iCloudDrive/Allgemein/dotfiles/ssh_keys/ 2>/dev/null || echo "iCloud Pfad nicht gefunden"

echo ""
echo "=== SSH Agent Status ==="
echo "SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
ssh-add -l 2>/dev/null || echo "Keine Keys im SSH Agent"
```

### Schritt 2: Entscheidung

**Wenn Keys in 1Password sind**:
→ Strategie C implementieren (1Password primary, iCloud backup)

**Wenn Keys NICHT in 1Password sind**:
→ Zuerst Keys in 1Password importieren, dann Strategie C

**Wenn du unsicher bist**:
→ Erstmal nichts ändern, Status Quo beibehalten

---

## 🎯 Empfehlung für dich

Basierend auf: "Ich hätte 1Password inkl. SSH Agent"

### Sofort

1. **Prüfe** welche Keys du wo hast (Script oben)

2. **Wenn Keys in 1Password sind**:
   - ✅ Implementiere Strategie C
   - ✅ SSH Config bekommt 1Password Agent
   - ✅ Filesystem Keys sind Fallback
   - ✅ iCloud bleibt als Backup

3. **Wenn Keys NICHT in 1Password sind**:
   - Importiere sie zuerst in 1Password
   - Dann Strategie C implementieren

### Mittelfristig

Nach erfolgreicher Umstellung:

- Filesystem Keys können gelöscht werden (optional)
- iCloud bleibt als Cold Backup
- Daily Use: 100% 1Password

---

## 🔒 Security Vergleich

| Aspekt | iCloud Copy | 1Password SSH Agent |
|--------|-------------|---------------------|
| Keys auf Disk | ❌ Ja | ✅ Nein |
| Biometric Auth | ❌ Nein | ✅ Ja (Touch ID) |
| Phishing-sicher | ⚠️ Nein | ✅ Ja |
| Sync zwischen Macs | ✅ Ja | ✅ Ja (besser) |
| Offline Access | ✅ Ja | ⚠️ Braucht 1Password |
| Audit Log | ❌ Nein | ✅ Ja |
| Expiry/Rotation | ❌ Nein | ✅ Ja |

---

## 📝 Nächster Schritt für dich

**Bitte teste erst**:

```bash
# Check ob 1Password SSH Agent läuft:
echo $SSH_AUTH_SOCK

# Sollte zeigen:
# ~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock
```

**Wenn JA**:
→ Ich kann die Strategie C Implementation machen

**Wenn NEIN**:
→ Zuerst 1Password SSH Agent aktivieren, dann Implementation

Was zeigt der Check bei dir?
