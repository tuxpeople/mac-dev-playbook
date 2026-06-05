---
> **VERALTET** (2026-06-05): Dotfiles werden seit Juni 2026 via [chezmoi](https://github.com/tuxpeople/dotfiles) verwaltet.
> `geerlingguy.dotfiles` und der Symlink-Ansatz sind nicht mehr aktiv. Diese Datei ist historische Referenz.

# Dotfiles vs. Ansible Repo - Struktur-Analyse

**Analysiert am**: 2025-10-24
**Zweck**: Klärung der Verantwortlichkeiten zwischen Dotfiles-Repo und Ansible-Repo

---

## 📊 Aktuelle Situation

### Dotfiles-Repo (`/Volumes/development/github/tuxpeople/dotfiles`)

**Genutzt durch Ansible via `geerlingguy.dotfiles` Role**

#### Echte Dotfiles (User-Konfiguration)

- `.bashrc`, `.bash_profile`, `.bash_prompt` - Shell-Konfiguration
- `.aliases`, `.exports`, `.functions` - Shell-Funktionen
- `.gitconfig`, `.gitattributes`, `.gitignore` - Git-Konfiguration
- `.vimrc`, `.gvimrc` - Vim-Editor
- `.tmux.conf`, `.screenrc` - Terminal-Multiplexer
- `.curlrc`, `.wgetrc` - Download-Tools
- `.inputrc` - Readline-Konfiguration
- `.ansible.cfg` - Ansible-User-Config
- `.k9s/` - Kubernetes CLI config

#### System-Konfiguration (sollte zu Ansible?)

- **`.macos`** (952 Zeilen!) - macOS defaults/Systemeinstellungen
  - Aktuell: Wird von `tasks/osx.yml` ausgeführt
  - Variable: `osx_script: "{{myhomedir}}/.macos --no-restart"`
  - Problem: **Riesiges Shell-Script** statt idempotente Ansible-Tasks

- **`machine/business_mac/Brewfile`** - Homebrew packages (Business)
- **`machine/private_mac/Brewfile`** - Homebrew packages (Private)
  - Aktuell: Genutzt via `homebrew_brewfile_dir: "{{dotfiles_repo_local_destination}}/machine/..."`
  - Problem: Ansible-managed Konfiguration liegt außerhalb des Ansible-Repos

#### Veraltete/Fragliche Dateien

- `.macos copy` - Duplikat?
- `Brewfile copy` in business_mac/ - Duplikat?
- `brew.sh` - Veraltete Homebrew-Installation (ruby -e curl)
- `bootstrap.sh`, `all.sh`, `git.sh` - Alte Bootstrap-Scripts?
- `Brewfile.lock.json` - Sollte in .gitignore

---

## 🔍 Detaillierte Analyse

### 1. `.macos` Script (952 Zeilen)

**Aktueller Workflow**:

```
1. geerlingguy.dotfiles Role klont Repo
2. Symlinkt .macos nach ~/.macos
3. tasks/osx.yml führt aus: ~/.macos --no-restart
```

**Probleme**:

- **Nicht idempotent**: Shell-Script läuft jedes Mal komplett durch
- **Keine Ansible-Vorteile**: Kein changed/ok reporting, keine conditionals
- **Schwer wartbar**: 952 Zeilen Shell vs. strukturierte Ansible-Tasks
- **Duplikation**: Viele defaults könnten mit `community.general.osx_defaults` gesetzt werden

**Beispiel-Inhalt**:

```bash
# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
```

**Bessere Lösung** (Ansible):

```yaml
- name: Configure macOS defaults
  community.general.osx_defaults:
    domain: NSGlobalDomain
    key: "{{ item.key }}"
    type: "{{ item.type }}"
    value: "{{ item.value }}"
  loop:
    - { key: NSNavPanelExpandedStateForSaveMode, type: bool, value: true }
    - { key: NSDocumentSaveNewDocumentsToCloud, type: bool, value: false }
    - { key: NSAutomaticCapitalizationEnabled, type: bool, value: false }
```

### 2. Brewfiles

**Aktueller Workflow**:

```
inventories/group_vars/business_mac/brew.yml:
  homebrew_brewfile_dir: "{{dotfiles_repo_local_destination}}/machine/business_mac/"

inventories/group_vars/private_mac/brew.yml:
  homebrew_brewfile_dir: "{{dotfiles_repo_local_destination}}/machine/private_mac/"
```

**Probleme**:

- Brewfiles liegen außerhalb des Ansible-Repos
- Änderungen an Packages = Änderungen in anderem Repo
- Brewfile-Management nicht in Ansible-Versionskontrolle

**Alternative Strukturen**:

**Option A**: Brewfiles ins Ansible-Repo

```
mac-dev-playbook/
  inventories/
    group_vars/
      business_mac/
        brew.yml         # homebrew_brewfile_dir: "../../../files/brewfiles/business_mac/"
      private_mac/
        brew.yml         # homebrew_brewfile_dir: "../../../files/brewfiles/private_mac/"
  files/
    brewfiles/
      business_mac/
        Brewfile
      private_mac/
        Brewfile
```

**Option B**: Ansible-managed Package-Listen statt Brewfiles

```yaml
# inventories/group_vars/business_mac/brew.yml
homebrew_installed_packages:
  - git
  - python
  - kubectl
homebrew_cask_apps:
  - docker
  - visual-studio-code
```

### 3. Bootstrap-Scripts

**Im Dotfiles-Repo**:

- `bootstrap.sh` - Symlinkt Dotfiles
- `brew.sh` - Installiert Homebrew (VERALTET)
- `all.sh` - Run all scripts
- `git.sh` - Git-Setup

**Problem**: Überschneidung mit Ansible-Bootstrap (`init.sh`, `init_light.sh`)

---

## 💡 Empfehlungen

### Klare Trennung der Verantwortlichkeiten

#### ✅ Im Dotfiles-Repo bleibt

**Zweck**: User-spezifische Konfiguration (portabel, persönlich)

- Shell-Config: `.bashrc`, `.bash_profile`, `.aliases`, `.functions`, `.exports`
- Editor-Config: `.vimrc`, `.gvimrc`
- Git-Config: `.gitconfig`, `.gitattributes`
- Tool-Configs: `.tmux.conf`, `.curlrc`, `.wgetrc`, `.k9s/`
- Terminal-Themes: `init/*.terminal`, `init/*.itermcolors`

#### ➡️ Ins Ansible-Repo migrieren

**Zweck**: System-Provisionierung (Mac-spezifisch, Ansible-managed)

1. **`.macos` → `tasks/macos-defaults.yml`**
   - Konvertieren: 952 Zeilen Shell → strukturierte Ansible-Tasks
   - Nutzen: `community.general.osx_defaults` Module
   - Vorteil: Idempotent, changed-reporting, wartbar

2. **Brewfiles → `inventories/group_vars/*/brew.yml`**
   - Option A: Brewfiles nach `files/brewfiles/` verschieben
   - Option B: In YAML-Listen konvertieren (empfohlen)
   - Vorteil: Eine Source of Truth, Ansible-Versionskontrolle

#### 🗑️ Aus Dotfiles-Repo entfernen

**Zweck**: Cleanup, Redundanz vermeiden

- `.macos` (wird zu Ansible-Tasks)
- `.macos copy` (Duplikat)
- `Brewfile`, `Brewfile copy` (werden zu Ansible)
- `brew.sh` (veraltet, Ansible übernimmt)
- `bootstrap.sh`, `all.sh`, `git.sh` (redundant zu Ansible)
- `Brewfile.lock.json` (build artifact, in .gitignore)

---

## 📋 Migrations-Plan

### Phase 1: Brewfiles (Einfach, sofortige Verbesserung)

**Option A - Brewfiles verschieben** (Schneller):

```bash
# 1. Struktur erstellen
mkdir -p files/brewfiles/{business_mac,private_mac}

# 2. Brewfiles kopieren
cp ~/development/github/tuxpeople/dotfiles/machine/business_mac/Brewfile \
   files/brewfiles/business_mac/
cp ~/development/github/tuxpeople/dotfiles/machine/private_mac/Brewfile \
   files/brewfiles/private_mac/

# 3. Ansible-Config updaten
# inventories/group_vars/business_mac/brew.yml:
homebrew_brewfile_dir: "../../../files/brewfiles/business_mac/"

# 4. Test, dann aus Dotfiles-Repo löschen
```

**Option B - In YAML konvertieren** (Besser langfristig):

```bash
# 1. Brewfile parsen und in YAML umwandeln
# 2. In group_vars/*/brew.yml integrieren
# 3. homebrew_brewfile_dir entfernen
```

### Phase 2: .macos Script konvertieren (Aufwändig)

**Vorgehen**:

1. `.macos` in Kategorien einteilen (General UI/UX, Finder, Dock, etc.)
2. Pro Kategorie eine Task-Datei erstellen (`tasks/macos/*.yml`)
3. Shell-defaults in `osx_defaults` Module konvertieren
4. Stufenweise migrieren (nicht alles auf einmal)
5. Testen auf Test-Mac
6. `.macos` aus Dotfiles entfernen wenn komplett migriert

**Beispiel-Kategorie**: `tasks/macos/general-ui.yml`

```yaml
---
- name: Set sidebar icon size to medium
  community.general.osx_defaults:
    domain: NSGlobalDomain
    key: NSTableViewDefaultSizeMode
    type: int
    value: 2

- name: Always show scrollbars
  community.general.osx_defaults:
    domain: NSGlobalDomain
    key: AppleShowScrollBars
    type: string
    value: "Always"

- name: Expand save panel by default
  community.general.osx_defaults:
    domain: NSGlobalDomain
    key: NSNavPanelExpandedStateForSaveMode
    type: bool
    value: true
```

### Phase 3: Dotfiles-Repo aufräumen

```bash
cd ~/development/github/tuxpeople/dotfiles

# Löschen:
rm .macos .macos\ copy
rm brew.sh bootstrap.sh all.sh git.sh
rm -rf machine/
rm .gitconfig-umb  # Falls nicht mehr gebraucht

# .gitignore erweitern:
echo "*.lock.json" >> .gitignore
```

---

## ⚠️ Risiken & Mitigation

### Risiko 1: .macos Konvertierung komplex

**Mitigation**:

- Stufenweise Migration (Kategorie für Kategorie)
- Test-Mac verwenden
- `.macos` vorerst parallel laufen lassen
- changed_when: false für Migration-Phase

### Risiko 2: Brewfiles haben spezielle Syntax

**Mitigation**:

- Erst kopieren (Option A), später konvertieren
- Brewfile-Format gut dokumentiert
- Ansible Homebrew-Role unterstützt Brewfiles

### Risiko 3: Dotfiles-Repo wird von mehreren Systemen genutzt?

**Mitigation**:

- Prüfen: Wird Dotfiles-Repo auch auf Linux/anderen Macs genutzt?
- Falls ja: .macos bleibt, aber wird nicht von Ansible gemanaged

---

## 🎯 Empfohlene Reihenfolge

1. **Sofort**: Dotfiles-Repo aufräumen (Duplikate löschen)
2. **Kurz**: Brewfiles ins Ansible-Repo kopieren (Option A)
3. **Mittel**: Brewfiles in YAML konvertieren (Option B)
4. **Lang**: .macos schrittweise zu Ansible-Tasks migrieren
5. **Final**: Veraltete Bootstrap-Scripts aus Dotfiles entfernen

---

## 📚 Referenzen

- geerlingguy.dotfiles Role: <https://github.com/geerlingguy/ansible-role-dotfiles>
- community.general.osx_defaults: <https://docs.ansible.com/ansible/latest/collections/community/general/osx_defaults_module.html>
- Homebrew Brewfile: <https://github.com/Homebrew/homebrew-bundle>

---

**Next Steps**: Beginne mit Phase 1 (Brewfiles) für schnelle Verbesserung
