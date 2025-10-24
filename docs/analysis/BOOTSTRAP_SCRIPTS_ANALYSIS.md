---
# Bootstrap Scripts Analyse

**Analysiert am**: 2025-10-24
**Zweck**: Review von init.sh, init_light.sh und scripts/macupdate - Konsolidierung prüfen

---

## 📊 Übersicht

Das Repository enthält **3 Bootstrap/Update Scripts** mit unterschiedlichen Zwecken:

| Script | Zeilen | Zweck | Verwendung |
|--------|--------|-------|------------|
| `init.sh` | 122 | Full Bootstrap (Fresh Mac) | Einmalig bei Mac-Setup |
| `init_light.sh` | 7 | Light Bootstrap (Existing Mac) | Wenn Ansible bereits vorhanden |
| `scripts/macupdate` | 281 | Daily Updates | Regelmäßige Wartung |

---

## 🔍 Detaillierte Analyse

### 1. init.sh - Full Bootstrap Script

**Zweck**: Komplettes Setup eines frischen Macs
**Aufruf**: Via curl von GitHub (kein lokales Checkout nötig)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)"
```

**Funktionen**:

#### Phase 1: Prerequisites (Zeilen 26-40)
```bash
- Fragt: "Are you logged into Mac Appstore?"
- Fragt: Hostname eingeben
- Sudo-Magic: Keep-alive loop für sudo
- Installiert Command Line Tools (falls nicht vorhanden)
```

**Besonderheit**: Sudo keep-alive loop läuft im Hintergrund
```bash
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
```

#### Phase 2: Repository & iCloud Files (Zeilen 42-79)
```bash
1. Klont Repo nach /tmp/git
2. Lädt iCloud-Dateien herunter (brctl download):
   - Library/Mobile Documents/.../dotfiles/filelists/filelist.txt
   - Library/Mobile Documents/.../dotfiles/filelists/folderlist.txt
   - Alle Dateien aus filelist.txt
   - Alle Ordner aus folderlist.txt
3. Führt add_vault_password aus (iCloud)
```

**Problem**: Hartcodierte Python-Version!
```bash
/Library/Developer/CommandLineTools/usr/bin/pip3.8 install --upgrade pip
/Library/Developer/CommandLineTools/usr/bin/pip3.8 install --user --requirement /tmp/git/requirements.txt
```
→ Python 3.8 ist veraltet, macOS hat mittlerweile Python 3.9+

#### Phase 3: Ansible Setup (Zeilen 80-89)
```bash
- pip3.8 install --requirement requirements.txt
- ansible-galaxy install -r requirements.yml
- PATH anpassen für Ansible
```

#### Phase 4: System Configuration (Zeilen 91-98)
```bash
- Kopiert limit.maxfiles.plist nach /Library/LaunchDaemons
- Kopiert limit.maxproc.plist nach /Library/LaunchDaemons
- Lädt LaunchDaemons
```

**Zweck**: Erhöht max open files/processes (wichtig für Docker, etc.)

#### Phase 5: Hostname Setup (Zeilen 107-114)
```bash
sudo scutil --set HostName ${newhostname}
sudo scutil --set LocalHostName ${newhostname}
sudo scutil --set ComputerName ${newhostname}
sudo dscacheutil -flushcache
```

#### Phase 6: Ansible Full Playbook (Zeilen 116-121)
```bash
ansible-playbook plays/full.yml \
  -i inventories \
  -l ${newhostname} \
  --extra-vars "newhostname=${newhostname}" \
  --connection=local
```

**Kommentierter Code** (Zeilen 100-105):
```bash
# echo "Getting Brewfile"
# if [[ $(hostname) == ws* ]]; then
#   curl -sfL https://raw.githubusercontent.com/tuxpeople/dotfiles/master/machine/business/Brewfile > files/Brewfile
# else
#   curl -sfL https://raw.githubusercontent.com/tuxpeople/dotfiles/master/machine/private/Brewfile > files/Brewfile
# fi
```
→ **Obsoleter Code**: Brewfiles werden jetzt via Inventory gemanaged

---

### 2. init_light.sh - Light Bootstrap

**Zweck**: Schnelles Setup wenn Mac bereits teilweise konfiguriert
**Aufruf**: Lokal im Repo-Directory
```bash
./init_light.sh
```

**Funktionen** (nur 7 Zeilen!):
```bash
1. pip3 install --requirement requirements.txt
2. PATH anpassen für Python user packages
3. ansible-galaxy install -r requirements.yml
```

**Use Case**:
- Mac hat bereits Python, pip, git
- Repo ist bereits geklont
- Nur Ansible-Dependencies müssen installiert werden

**Problem**: Verwendet `pip3` ohne Version → kann unterschiedliche Python-Versionen nutzen

---

### 3. scripts/macupdate - Daily Update Script

**Zweck**: Regelmäßige System-Updates und Wartung
**Aufruf**: Symlinked nach ~/iCloudDrive/Allgemein/bin/macupdate
```bash
macupdate
```

**Funktionen**:

#### Moderne Features:
```bash
- set -euo pipefail (fail-safe)
- Proper logging mit Timestamps und Farben
- Environment variable overrides (PYTHON_VERSION, REPO_DIR)
- Symlink-Auflösung für flexible Installation
- Detailliertes Error-Handling
```

#### Phase 1: Tool Installation (Zeilen 60-82)
```bash
- Prüft Homebrew
- Installiert: pyenv, pyenv-virtualenv, mise
```

#### Phase 2: Python Setup (Zeilen 84-133)
```bash
- Setup pyenv (mit eval "$(pyenv init -)")
- Installiert Python 3.11.8 (konfigurierbar!)
- Erstellt virtualenv: mac-dev-playbook-venv
- Aktiviert virtualenv
```

**Vorteil**: Python-Version ist Variable!
```bash
PYTHON_VERSION="${PYTHON_VERSION:-3.11.8}"
```

#### Phase 3: Repository Update (Zeilen 147-170)
```bash
- cd ins Repo
- Prüft uncommitted changes → stash
- git pull --rebase
```

#### Phase 4: Dependencies (Zeilen 172-202)
```bash
- pip install --upgrade pip
- pip install --requirement requirements.txt
- ansible-galaxy install -r requirements.yml
```

#### Phase 5: Ansible Run (Zeilen 204-226)
```bash
ansible-playbook plays/update.yml \
  -i inventories \
  -l $(hostname -s) \
  --connection=local
```

**Wichtig**: Führt `plays/update.yml` aus (nicht `plays/full.yml`!)

#### Phase 6: Post-Playbook Tasks (Zeilen 228-248)
```bash
- Spotify Quarantine Fix (bekanntes Homebrew-Problem)
- CMDB Update (optional, wenn Script in iCloud vorhanden)
```

---

## 🔀 Vergleich & Überschneidungen

### Gemeinsame Funktionalität

| Funktion | init.sh | init_light.sh | macupdate |
|----------|---------|---------------|-----------|
| Command Line Tools installieren | ✅ | ❌ | ✅ (Check) |
| Python installieren | ✅ (pip3.8) | ❌ | ✅ (pyenv) |
| requirements.txt installieren | ✅ | ✅ | ✅ |
| requirements.yml installieren | ✅ | ✅ | ✅ |
| Git repo update | ❌ (clone) | ❌ | ✅ (pull) |
| Ansible playbook ausführen | ✅ (full.yml) | ❌ | ✅ (update.yml) |
| Error handling | Basic | None | Advanced |
| Logging | Basic | None | Advanced |

### Unterschiede

#### init.sh vs macupdate

| Feature | init.sh | macupdate |
|---------|---------|-----------|
| **Zweck** | Einmalig (Bootstrap) | Regelmäßig (Updates) |
| **Python** | Hartcodiert pip3.8 | pyenv + virtualenv |
| **Playbook** | plays/full.yml | plays/update.yml |
| **iCloud-Files** | Download via brctl | Nicht benötigt |
| **Hostname Setup** | Ja, interaktiv | Nein |
| **LaunchDaemons** | Installiert limit plist | Nicht benötigt |
| **Repo** | Clone nach /tmp | Update via git pull |
| **Sudo Magic** | Background loop | Nicht benötigt |

#### init_light.sh vs macupdate

`init_light.sh` ist praktisch **obsolet** durch `macupdate`:
- Gleiche Basis-Funktionalität
- Aber macupdate hat: pyenv, virtualenv, error handling, logging
- init_light.sh ist nur nützlich wenn pyenv NICHT gewünscht

---

## ⚠️ Probleme & Verbesserungspotential

### init.sh Probleme

#### 1. Hartcodierte Python-Version (CRITICAL)
```bash
/Library/Developer/CommandLineTools/usr/bin/pip3.8 install ...
```
**Problem**:
- Python 3.8 ist EOL (End of Life)
- macOS Sonoma/Sequoia haben Python 3.9+
- Script schlägt fehl auf neueren Macs

**Fix**: Verwende `python3` statt `pip3.8`
```bash
/Library/Developer/CommandLineTools/usr/bin/python3 -m pip install ...
```

#### 2. iCloud Dependency (HIGH)
```bash
# Zeilen 50-76: Lädt iCloud-Dateien via brctl
for FILE in Library/Mobile\ Documents/com~apple~CloudDocs/...
```

**Problem**:
- iCloud muss eingeloggt und synced sein
- Filelists müssen existieren und aktuell sein
- Nicht testbar ohne iCloud-Account
- Nicht portabel auf andere User

**Fragen**:
- Was steht in filelist.txt? Welche Files sind kritisch?
- Könnte man diese Files anders bereitstellen? (Git LFS, Ansible Vault, 1Password)

#### 3. Obsoleter kommentierter Code
```bash
# echo "Getting Brewfile"
# if [[ $(hostname) == ws* ]]; then ...
```

**Fix**: Löschen, wird nicht mehr verwendet

#### 4. Keine Fehlerbehandlung
```bash
git clone https://github.com/tuxpeople/mac-dev-playbook.git /tmp/git || exit 1
```

Gut, aber:
- Kein cleanup bei Fehler
- /tmp/git könnte bereits existieren
- Kein Rollback bei Ansible-Fehler

#### 5. set -e ist auskommentiert
```bash
# set -e
```

**Problem**: Script läuft weiter bei Fehlern (außer explizites `|| exit 1`)

---

### init_light.sh Probleme

#### 1. Keine Python-Version spezifiziert
```bash
pip3 install --requirement requirements.txt
```
→ Nutzt system `pip3`, könnte verschiedene Python-Versionen sein

#### 2. Kein Error Handling
Kein `set -e`, keine Checks, außer `|| exit 1`

#### 3. PATH wird nur temporär gesetzt
```bash
PATH="/usr/local/bin:$(python3 -m site --user-base)/bin:$PATH"
export PATH
```
→ Nur für dieses Script, nicht persistent

---

### macupdate - Bereits gut!

**Stärken**:
- Modernes Bash (set -euo pipefail)
- Proper error handling und logging
- Konfigurierbar (PYTHON_VERSION, REPO_DIR)
- pyenv + virtualenv = saubere Python-Isolation
- Symlink-Auflösung

**Minimale Verbesserungen**:
1. **Deprecated CLI Tools Check**: Zeile 139 prüft nur Python-Binary
   ```bash
   if [ ! -f "/Library/Developer/CommandLineTools/usr/bin/python3" ]; then
   ```
   → Besser: `xcode-select -p` verwenden

2. **Python Version Mismatch**: PYTHON_VERSION ist 3.11.8, aber init.sh nutzt 3.8
   → Sollten synchronisiert sein

---

## 💡 Empfehlungen

### Option 1: Modernisiere init.sh (Minimal Invasive)

**Fixes**:
1. **Ersetze hartcodierte Python-Version**:
   ```bash
   # Alt:
   /Library/Developer/CommandLineTools/usr/bin/pip3.8 install ...

   # Neu:
   PYTHON_BIN="/Library/Developer/CommandLineTools/usr/bin/python3"
   ${PYTHON_BIN} -m pip install ...
   ```

2. **Aktiviere set -e**:
   ```bash
   set -euo pipefail
   ```

3. **Lösche obsoleten Code** (Zeilen 100-105)

4. **Dokumentiere iCloud-Dependency** besser

**Pro**: Minimale Änderung, init.sh bleibt eigenständig
**Contra**: Bleibt komplex, iCloud-Dependency bleibt

---

### Option 2: Konsolidiere zu einem Bootstrap-Script (Empfohlen)

**Idee**: Ein einziges `scripts/bootstrap` mit Modes

```bash
scripts/bootstrap --mode=full    # Wie init.sh
scripts/bootstrap --mode=light   # Wie init_light.sh
scripts/bootstrap --mode=update  # Alias für macupdate
```

**Struktur**:
```bash
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:---mode=full}"

case "${MODE}" in
  --mode=full)
    # Full bootstrap (fresh Mac)
    check_prerequisites
    install_cli_tools
    setup_icloud_files  # Optional mit --skip-icloud
    setup_hostname
    install_launchdaemons
    setup_python_env
    install_ansible
    run_full_playbook
    ;;
  --mode=light)
    # Light bootstrap (Ansible only)
    setup_python_env
    install_ansible
    ;;
  --mode=update)
    # Daily updates (wie macupdate)
    exec "$(dirname "$0")/macupdate"
    ;;
  *)
    usage
    exit 1
    ;;
esac
```

**Vorteile**:
- Ein Script zu warten statt drei
- Gemeinsame Funktionen (logging, error handling)
- Konsistente Python-Version über alle Modes
- Moderne Bash-Practices überall

**Nachteile**:
- Breaking Change für existierende curl-Aufruf
- Migration nötig

---

### Option 3: Status Quo mit Dokumentation (Pragmatisch)

**Keep**:
- `init.sh`: Für Bootstrap via curl (mit Fixes)
- `init_light.sh`: Deprecaten oder löschen (redundant zu macupdate ohne --update)
- `scripts/macupdate`: Für Daily Updates (bereits perfekt)

**Dokumentation**:
```markdown
# Bootstrap & Update Scripts

## Fresh Mac Setup
curl -fsSL https://raw.githubusercontent.com/.../init.sh | bash

## Existing Mac - Install Ansible
./init_light.sh  # DEPRECATED, use: scripts/macupdate --skip-update

## Daily Updates
scripts/macupdate  # or via symlink: macupdate
```

**Pro**:
- Minimaler Aufwand
- Keine Breaking Changes
- init.sh bleibt curl-bar

**Contra**:
- Drei Scripts zu warten
- Inkonsistente Python-Versionen
- init_light.sh redundant

---

## 🎯 Konkrete Empfehlung

### Phase 1: Sofort (Quick Wins)

1. **init.sh fixes**:
   ```bash
   - Ersetze pip3.8 → python3 -m pip
   - Aktiviere set -e
   - Lösche obsoleten Brewfile-Code (Zeilen 100-105)
   ```

2. **init_light.sh**:
   ```bash
   - Deprecate mit Warnung: "Use scripts/macupdate instead"
   - Oder: Mache es zu Wrapper für macupdate
   ```

3. **Dokumentation**:
   - README.md: Wann welches Script verwenden
   - Erkläre iCloud-Dependency in init.sh

### Phase 2: Optional (Langfristig)

4. **Konsolidierung prüfen**:
   - Wenn init.sh oft geändert werden muss → Option 2
   - Wenn stabil bleibt → Option 3

5. **iCloud-Dependency reduzieren**:
   - Prüfen: Welche Files aus iCloud sind wirklich nötig?
   - Alternativen: Ansible Vault, 1Password Documents, Git LFS

---

## 📋 iCloud Files Investigation

**Fragen zu klären**:

1. **Was steht in den Filelists?**
   ```bash
   cat ~/Library/Mobile\ Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/filelist.txt
   cat ~/Library/Mobile\ Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/folderlist.txt
   ```

2. **Welche Files sind Bootstrap-kritisch?**
   - SSH Keys? → Ansible Vault oder 1Password
   - Vault Password? → Interaktiv prompt oder Keychain
   - Config Files? → Schon im Dotfiles-Repo

3. **Können wir Bootstrap ohne iCloud?**
   - Ansible Vault für Secrets
   - Git-Repo für Configs
   - Interaktive Prompts für Credentials

---

## 📊 Decision Matrix

| Kriterium | Option 1 (Fixes) | Option 2 (Konsolidierung) | Option 3 (Status Quo + Docs) |
|-----------|------------------|---------------------------|-------------------------------|
| **Aufwand** | 🟢 Niedrig (2h) | 🔴 Hoch (1-2 Tage) | 🟢 Niedrig (1h) |
| **Wartbarkeit** | 🟡 Mittel (3 Scripts) | 🟢 Hoch (1 Script) | 🔴 Niedrig (3 Scripts) |
| **Breaking Changes** | 🟢 Keine | 🔴 Ja (curl URL) | 🟢 Keine |
| **Modernität** | 🟡 Teilweise | 🟢 Voll | 🔴 Minimal |
| **Testing** | 🟢 Einfach | 🟡 Komplex | 🟢 Einfach |

---

## 🚀 Next Steps

1. **Sofort** (Phase 1 Fixes):
   - [ ] Fix init.sh Python-Version
   - [ ] Aktiviere set -e in init.sh
   - [ ] Lösche obsoleten Code
   - [ ] Deprecate init_light.sh oder Wrapper erstellen

2. **Investigate**:
   - [ ] Prüfe iCloud filelists: Was ist drin?
   - [ ] Teste init.sh auf frischem Mac (VM?)
   - [ ] Dokumentiere add_vault_password Script

3. **Dokumentation**:
   - [ ] README.md: Bootstrap-Sektion erweitern
   - [ ] Erkläre wann welches Script
   - [ ] iCloud-Requirements dokumentieren

4. **Optional** (wenn Zeit/Bedarf):
   - [ ] Entscheide: Konsolidierung oder Status Quo
   - [ ] Implementiere gewählte Option

---

## 📚 Referenzen

- Apple Command Line Tools: https://developer.apple.com/download/all/
- pyenv best practices: https://github.com/pyenv/pyenv#readme
- Bash strict mode: http://redsymbol.net/articles/unofficial-bash-strict-mode/
- iCloud brctl: `man brctl` (macOS utility für iCloud Drive control)

---

**Status**: Ready for review
**Empfehlung**: **Option 1 (Fixes) + Phase 1** als Quick Win, langfristig **Option 2 (Konsolidierung)** evaluieren
