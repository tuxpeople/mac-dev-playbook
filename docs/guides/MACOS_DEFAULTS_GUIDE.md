# macOS Defaults Export & Management Guide

**Erstellt**: 2025-10-22

## Übersicht

Dieses Dokument erklärt wie du herausfinden kannst, welche macOS Einstellungen du manuell geändert hast und diese in dein Ansible Playbook integrieren kannst.

## Problem

Du hast vermutlich Einstellungen auf deinem Mac konfiguriert die nicht in deinem Playbook erfasst sind:

- System Preferences Änderungen
- Finder Einstellungen
- Dock Konfiguration
- Keyboard Shortcuts
- Etc.

Diese Einstellungen gehen verloren bei einem neuen Mac Setup.

## Lösung: Zwei Scripts

### 1. `export-macos-defaults.sh` - Export ALLER Settings

Exportiert alle wichtigen macOS defaults Einstellungen.

**Verwendung**:

```bash
cd ~/development/github/tuxpeople/mac-dev-playbook

# Export to file
./scripts/export-macos-defaults.sh ~/Desktop/my-macos-settings.sh

# Or print to terminal
./scripts/export-macos-defaults.sh
```

**Output**: Ein Shell-Script mit allen `defaults write` Commands:

```bash
#!/usr/bin/env bash
# macOS Defaults Configuration

defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 48
# ... etc
```

**Domains die exportiert werden**:

- `NSGlobalDomain` - Globale System-Einstellungen
- `com.apple.dock` - Dock Einstellungen
- `com.apple.finder` - Finder Einstellungen
- `com.apple.Safari` - Safari Einstellungen
- `com.apple.screencapture` - Screenshot Einstellungen
- Und viele mehr...

---

### 2. `compare-macos-defaults.sh` - Vergleich mit Baseline

Vergleicht aktuelle Einstellungen mit einem Baseline (fresh system oder früherem Zustand).

**Erste Verwendung - Baseline erstellen**:

```bash
./scripts/compare-macos-defaults.sh

# Output:
# No baseline file found.
# Creating baseline at: /Users/tdeutsch/.macos-defaults-baseline.txt
# ✓ Baseline created!
```

**Spätere Verwendung - Änderungen finden**:

```bash
# Nachdem du Einstellungen geändert hast:
./scripts/compare-macos-defaults.sh

# Output:
# === Changed Settings ===
#
# Domain: com.apple.dock
# + NEW: autohide = 1
# + NEW: tilesize = 48
#
# Domain: com.apple.finder
# + NEW: ShowPathbar = 1
#
# Total changes: 3
#
# ✓ Script generated: /tmp/apply-defaults-changes-1234.sh
```

---

## Workflow: Einstellungen zu Playbook hinzufügen

### Schritt 1: Baseline erstellen (auf einem frischen Mac oder vor Änderungen)

```bash
# Auf dem aktuellen Mac (oder frischem Test-Mac)
cd ~/development/github/tuxpeople/mac-dev-playbook
./scripts/compare-macos-defaults.sh
```

### Schritt 2: Einstellungen ändern

Ändere jetzt deine System Preferences, Finder Einstellungen, etc.

### Schritt 3: Änderungen exportieren

```bash
# Finde heraus was sich geändert hat
./scripts/compare-macos-defaults.sh

# Exportiere alle Einstellungen
./scripts/export-macos-defaults.sh ~/Desktop/my-settings.sh
```

### Schritt 4: Review & Integration

**Review** `~/Desktop/my-settings.sh`:

```bash
# Öffne in Editor
code ~/Desktop/my-settings.sh

# Oder durchsuchen:
grep -i "dock" ~/Desktop/my-settings.sh
grep -i "finder" ~/Desktop/my-settings.sh
```

**Entferne** unwichtige oder temporäre Settings:

- Session-spezifische Daten
- Kürzlich verwendete Dateien
- Cache-Werte
- Sehr lange/binäre Werte

**Wichtige Settings identifizieren**:

```bash
# Finder
grep "com.apple.finder" ~/Desktop/my-settings.sh

# Dock
grep "com.apple.dock" ~/Desktop/my-settings.sh

# Screenshots
grep "com.apple.screencapture" ~/Desktop/my-settings.sh

# Global
grep "NSGlobalDomain" ~/Desktop/my-settings.sh
```

### Schritt 5: Integration ins Playbook

Du hast mehrere Optionen:

#### Option A: Dotfiles Repository (empfohlen für User-Einstellungen)

Wenn du bereits ein dotfiles Repository hast:

1. **Kopiere relevante Settings** in dein dotfiles `.macos` script:

   ```bash
   # In deinem dotfiles repo (z.B. ~/development/github/tuxpeople/dotfiles)
   vim .macos
   ```

2. **Füge neue defaults hinzu**:

   ```bash
   ###############################################################################
   # Finder                                                                      #
   ###############################################################################

   # Show path bar
   defaults write com.apple.finder ShowPathbar -bool true

   # Show status bar
   defaults write com.apple.finder ShowStatusBar -bool true

   ###############################################################################
   # Dock                                                                        #
   ###############################################################################

   # Auto-hide dock
   defaults write com.apple.dock autohide -bool true

   # Set tile size
   defaults write com.apple.dock tilesize -int 48
   ```

3. **Playbook wird automatisch synchronisieren** via `geerlingguy.dotfiles` role

#### Option B: tasks/osx.yml (für System-wide Einstellungen)

Für System-Einstellungen die nicht User-spezifisch sind:

1. **Öffne** `tasks/osx.yml`:

   ```bash
   vim tasks/osx.yml
   ```

2. **Füge neue Tasks hinzu**:

   ```yaml
   # Disable natural scrolling
   - name: Disable natural scrolling
     osx_defaults:
       domain: NSGlobalDomain
       key: com.apple.swipescrolldirection
       type: bool
       value: false
     become: false

   # Set keyboard repeat rate
   - name: Set keyboard repeat rate
     osx_defaults:
       domain: NSGlobalDomain
       key: KeyRepeat
       type: int
       value: 2
     become: false
   ```

#### Option C: tasks/post/* (für App-spezifische Settings)

Für spezifische Applikationen:

1. **Erstelle neue Task-Datei** (z.B. `tasks/post/my-settings.yml`):

   ```yaml
   ---
   # Custom macOS Settings

   - name: Configure Finder preferences
     block:
       - name: Show all filename extensions
         osx_defaults:
           domain: NSGlobalDomain
           key: AppleShowAllExtensions
           type: bool
           value: true

       - name: Show hidden files
         osx_defaults:
           domain: com.apple.finder
           key: AppleShowAllFiles
           type: bool
           value: true

       - name: Restart Finder to apply changes
         command: killall Finder
         changed_when: false
         failed_when: false
     become: false

   - name: Configure Dock preferences
     block:
       - name: Auto-hide Dock
         osx_defaults:
           domain: com.apple.dock
           key: autohide
           type: bool
           value: true

       - name: Set Dock size
         osx_defaults:
           domain: com.apple.dock
           key: tilesize
           type: int
           value: 48

       - name: Restart Dock to apply changes
         command: killall Dock
         changed_when: false
         failed_when: false
     become: false
   ```

2. **Registriere in** `inventories/group_vars/macs/post.yml`:

   ```yaml
   post_provision_tasks:
     - "{{ playbook_dir }}/tasks/post/*.yml"
     - "{{ playbook_dir }}/tasks/post/my-settings.yml"  # Explizit wenn nötig
   ```

---

## Ansible osx_defaults Module vs. Shell Commands

### Empfohlen: osx_defaults module (Ansible Community.General)

```yaml
- name: Example using osx_defaults
  community.general.osx_defaults:
    domain: com.apple.finder
    key: ShowPathbar
    type: bool
    value: true
  become: false
```

**Vorteile**:

- ✅ Idempotent (ändert nur wenn nötig)
- ✅ Proper change detection
- ✅ Type-safe

**Installation** (falls nicht vorhanden):

```bash
ansible-galaxy collection install community.general
```

### Alternative: Shell commands

```yaml
- name: Get current value
  command: defaults read com.apple.finder ShowPathbar
  register: pathbar_current
  changed_when: false
  failed_when: false

- name: Set value if different
  command: defaults write com.apple.finder ShowPathbar -bool true
  when: pathbar_current.stdout != "1"
```

---

## Nützliche Befehle

### Alle Domains auflisten

```bash
defaults domains
```

### Spezifische Domain lesen

```bash
defaults read com.apple.dock
defaults read com.apple.finder
defaults read NSGlobalDomain
```

### Spezifischen Key lesen

```bash
defaults read com.apple.dock autohide
defaults read com.apple.finder ShowPathbar
```

### Suchen nach spezifischen Einstellungen

```bash
# Finde alle Settings mit "pathbar"
defaults find pathbar

# Finde alle Settings mit "keyboard"
defaults find keyboard
```

### Aktuellen Wert eines Keys finden

```bash
# Finder: Show Path Bar
defaults read com.apple.finder ShowPathbar

# Dock: Auto-hide
defaults read com.apple.dock autohide

# Global: Keyboard Repeat
defaults read NSGlobalDomain KeyRepeat
```

### Änderungen in Echtzeit beobachten

```bash
# Terminal 1: Watch defaults
watch -n 1 'defaults read com.apple.dock | head -20'

# Terminal 2: Ändere Dock Einstellungen in System Preferences
# → Siehst du sofort im ersten Terminal
```

---

## Häufige macOS Einstellungen

### Finder

```yaml
# Show all filename extensions
- osx_defaults:
    domain: NSGlobalDomain
    key: AppleShowAllExtensions
    type: bool
    value: true

# Show hidden files
- osx_defaults:
    domain: com.apple.finder
    key: AppleShowAllFiles
    type: bool
    value: true

# Show path bar
- osx_defaults:
    domain: com.apple.finder
    key: ShowPathbar
    type: bool
    value: true

# Show status bar
- osx_defaults:
    domain: com.apple.finder
    key: ShowStatusBar
    type: bool
    value: true

# Default to list view
- osx_defaults:
    domain: com.apple.finder
    key: FXPreferredViewStyle
    type: string
    value: Nlsv
```

### Dock

```yaml
# Auto-hide Dock
- osx_defaults:
    domain: com.apple.dock
    key: autohide
    type: bool
    value: true

# Dock size
- osx_defaults:
    domain: com.apple.dock
    key: tilesize
    type: int
    value: 48

# Dock position (bottom, left, right)
- osx_defaults:
    domain: com.apple.dock
    key: orientation
    type: string
    value: bottom

# Minimize effect (genie, scale)
- osx_defaults:
    domain: com.apple.dock
    key: mineffect
    type: string
    value: scale

# Show recent apps in Dock
- osx_defaults:
    domain: com.apple.dock
    key: show-recents
    type: bool
    value: false
```

### Screenshots

```yaml
# Save screenshots to Desktop
- osx_defaults:
    domain: com.apple.screencapture
    key: location
    type: string
    value: "${HOME}/Desktop"

# Disable shadow in screenshots
- osx_defaults:
    domain: com.apple.screencapture
    key: disable-shadow
    type: bool
    value: true

# Screenshot format (png, jpg, pdf)
- osx_defaults:
    domain: com.apple.screencapture
    key: type
    type: string
    value: png
```

### Keyboard & Mouse

```yaml
# Enable full keyboard access (Tab through all controls)
- osx_defaults:
    domain: NSGlobalDomain
    key: AppleKeyboardUIMode
    type: int
    value: 3

# Key repeat rate (fastest = 2)
- osx_defaults:
    domain: NSGlobalDomain
    key: KeyRepeat
    type: int
    value: 2

# Delay until repeat (shortest = 15)
- osx_defaults:
    domain: NSGlobalDomain
    key: InitialKeyRepeat
    type: int
    value: 15

# Disable auto-correct
- osx_defaults:
    domain: NSGlobalDomain
    key: NSAutomaticSpellingCorrectionEnabled
    type: bool
    value: false

# Disable natural scrolling
- osx_defaults:
    domain: NSGlobalDomain
    key: com.apple.swipescrolldirection
    type: bool
    value: false

# Trackpad: enable tap to click
- osx_defaults:
    domain: com.apple.driver.AppleBluetoothMultitouch.trackpad
    key: Clicking
    type: bool
    value: true
  become: true  # System-level setting
```

---

## Testing

### Test auf Test-User Account

1. **Erstelle Test-User**:

   ```bash
   # System Preferences → Users & Groups → Add User
   # Oder via command:
   sudo dscl . -create /Users/testuser
   sudo dscl . -create /Users/testuser UserShell /bin/bash
   sudo dscl . -create /Users/testuser RealName "Test User"
   sudo dscl . -create /Users/testuser UniqueID 502
   sudo dscl . -create /Users/testuser PrimaryGroupID 20
   sudo dscl . -create /Users/testuser NFSHomeDirectory /Users/testuser
   sudo dscl . -passwd /Users/testuser testpass
   sudo mkdir /Users/testuser
   sudo chown -R testuser:staff /Users/testuser
   ```

2. **Login als testuser**

3. **Run playbook**:

   ```bash
   ansible-playbook plays/full.yml -i inventories -l $(hostname) --connection=local
   ```

4. **Verify settings**:

   ```bash
   defaults read com.apple.finder ShowPathbar
   # Should output: 1
   ```

---

## Integration in bestehendes Playbook

### Aktuell in deinem Playbook

**tasks/osx.yml** wird ausgeführt via:

```yaml
# plays/full.yml oder main.yml
- import_tasks: tasks/osx.yml
  when: configure_osx
  tags: ['osx']
```

**Konfiguriert** via:

```yaml
# inventories/group_vars/macs/general.yml
osx_script: "{{myhomedir}}/.macos --no-restart"
```

Das bedeutet: Du hast bereits ein `.macos` script in deinem dotfiles repo!

### Empfohlene Erweiterung

1. **Überprüfe** dein dotfiles repo:

   ```bash
   cat ~/development/github/tuxpeople/dotfiles/.macos
   # oder wo immer dein dotfiles repo liegt
   ```

2. **Füge neue Settings hinzu** zu `.macos`:

   ```bash
   # Am Ende von .macos hinzufügen:

   ###############################################################################
   # Custom Settings (discovered via export-macos-defaults.sh)
   ###############################################################################

   # Finder: Show path bar
   defaults write com.apple.finder ShowPathbar -bool true

   # Dock: Auto-hide
   defaults write com.apple.dock autohide -bool true

   # Etc...
   ```

3. **Commit & Push** dotfiles:

   ```bash
   cd ~/development/github/tuxpeople/dotfiles
   git add .macos
   git commit -m "Add discovered macOS defaults"
   git push
   ```

4. **Playbook synchronisiert automatisch** beim nächsten Run!

---

## Zusammenfassung

1. **Export aktuelle Settings**:

   ```bash
   ./scripts/export-macos-defaults.sh ~/Desktop/my-settings.sh
   ```

2. **Review & Clean**:
   - Entferne unwichtige Settings
   - Identifiziere wichtige Änderungen

3. **Integration**:
   - Option A: Dotfiles `.macos` script (empfohlen)
   - Option B: `tasks/osx.yml`
   - Option C: `tasks/post/my-settings.yml`

4. **Test**:
   - Auf Test-User oder VM
   - Verify mit `defaults read`

5. **Commit**:
   - Git commit & push
   - Dokumentiere in README was die Settings machen

---

## Troubleshooting

### Settings werden nicht angewendet

**Problem**: Nach Playbook run sind Settings nicht aktiv.

**Lösung**: Restart betroffene App:

```bash
killall Finder
killall Dock
killall SystemUIServer
```

Oder in Ansible:

```yaml
- name: Restart Dock
  command: killall Dock
  changed_when: false
  failed_when: false
```

### Settings verschwinden nach Reboot

**Problem**: Einstellungen sind nach Neustart wieder weg.

**Ursache**: Settings wurden nicht im richtigen Kontext geschrieben (user vs. system).

**Lösung**: Prüfe `become` flag:

```yaml
# User settings (die meisten)
- osx_defaults:
    domain: com.apple.finder
    key: ShowPathbar
    type: bool
    value: true
  become: false  # ← User context

# System settings
- osx_defaults:
    domain: /Library/Preferences/com.apple.loginwindow
    key: DSBindTimeout
    type: int
    value: 4
  become: true  # ← System context
```

### Defaults read zeigt falschen Wert

**Problem**: `defaults read` zeigt alten Wert trotz `defaults write`.

**Ursache**: App muss neu gestartet werden oder cached den Wert.

**Lösung**:

```bash
# Force reload
killall cfprefsd
# Dann App neu starten
```

---

## Nächste Schritte

1. ✅ Scripts sind erstellt in `scripts/`
2. 📝 Exportiere deine aktuellen Settings
3. 🔍 Review was wichtig ist
4. 📋 Integriere in dotfiles oder tasks
5. ✅ Test auf Test-User
6. 💾 Commit & Push
