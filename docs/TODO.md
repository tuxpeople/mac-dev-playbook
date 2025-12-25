# TODO List

Langfristige Aufgaben und Ideen für zukünftige Sessions.

## Zu erledigen

- [ ] **GitHub Repository Cloning: Ansible vs. ghorg**
  - **Problem**: Ansible-basiertes Repo-Cloning (tasks/post/github.yml) hat Nachteile:
    - Einige private Repos schlagen fehl (trotz Token)
    - Dupliziert Funktionalität von ghorg (bereits konfiguriert in dotfiles)
    - Verlangsamt init.sh (nicht essentiell für Bootstrap)
  - **Status**: Quick-Fixes angewendet (2025-12-25):
    - ✅ Loop variable 'item' conflict behoben (loop_var: repo)
    - ✅ ignore_errors: true für fehlschlagende Repos
  - **Optionen**:
    1. **Behalten**: Repos sind automatisch nach init.sh verfügbar
    2. **Zu ghorg wechseln**: Manuell `ghorg clone tuxpeople --clone-type=user` nach 1Password-Login
    3. **Hybrid**: github.yml optional machen (Tag oder Variable)
  - **Entscheidung**: Noch offen - später evaluieren

- [ ] **Bootstrap Scripts Review & Konsolidierung** 🔄 **PHASE 1 ABGESCHLOSSEN**
  - **Status**: Vollständige Analyse + Quick Wins implementiert
  - **Analyse**: `docs/analysis/BOOTSTRAP_SCRIPTS_ANALYSIS.md` (565 Zeilen)
    - Vergleich: `init.sh` vs `init_light.sh` vs `scripts/macupdate`
    - Decision Matrix für Konsolidierungsoptionen
    - iCloud-Dependency Evaluation
  - **Fixes angewendet** (Commit `14050dc`):
    - ✅ `init.sh`: Python 3.8 → python3 (nicht mehr EOL-Version)
    - ✅ `init.sh`: `set -e` aktiviert für fail-fast behavior
    - ✅ `init.sh`: Obsoleten Brewfile-Code entfernt (Zeilen 100-105)
    - ✅ `init_light.sh`: Als DEPRECATED markiert mit Hinweis auf `scripts/macupdate`
  - **Nächste Schritte**:
    - [x] README.md: Bootstrap-Sektion erweitern (Wann welches Script?) ✅ **ERLEDIGT (2025-12-24)**
    - [ ] iCloud-Dependency untersuchen: Was steht in filelists?
    - [ ] Optional: Konsolidierung evaluieren (siehe Analyse Option 2)

- [ ] **Dotfiles vs. Ansible Repo - Phase 3** 🔄 **PHASE 1 & 2 ABGESCHLOSSEN (2025-12-24)**
  - **Phase 1: Brewfiles verschieben** ✅ **ERLEDIGT (2025-12-22)**
    - Brewfiles von dotfiles nach `files/brewfile/business_mac/` und `private_mac/`
    - Config aktualisiert in `brew.yml` (beide Groups)
    - Wichtige Erkenntnis: Brewfiles dürfen NICHT in `group_vars/` (wird als YAML geparst)
    - Dokumentiert in `docs/BREWFILE_MIGRATION.md`
    - Siehe auch: `docs/analysis/REPOSITORY_REVIEW.md` Priority 2
  - **Phase 2: .macos konvertieren** ✅ **ERLEDIGT (2025-12-24)**
    - 89 Settings nach Ansible migriert (defaults.yml: 12 → 90)
    - .macos von 952 → 365 Zeilen reduziert (-62%)
    - Orphaned Comments entfernt (264 Zeilen)
    - Broken Settings dokumentiert (Safari/Mail auf macOS 26.2)
    - Manuelle Checkliste erstellt für nicht automatisierbare Settings
    - Siehe: `docs/sessions/FINAL_MIGRATION_STATS_2025-12-24.md`
  - **Phase 3: Dotfiles-Repo aufräumen** (offen)
    - .macos.backup* Dateien entfernen
    - Nur echte Dotfiles behalten

- [ ] **myenv Variable Refactoring**
  - **Aktuell**: Variable `myenv` wird doppelt definiert (group_vars + runtime fact)
  - **Ziel**: Ersetzen durch Ansible's eingebaute `group_names` Variable
  - **Änderungen**:
    - `when: myenv == "business_mac"` → `when: "'business_mac' in group_names"`
    - `post.yml`: `{{ myenv }}-settings.yml` → Bedingte Include basierend auf group_names
    - `tasks/pre/additional-facts.yml`: myenv-Fact entfernen
    - `inventories/group_vars/business_mac/general.yml`: myenv entfernen
    - `inventories/group_vars/private_mac/general.yml`: myenv entfernen
  - **Betroffen**: ~5-10 Dateien (grep nach "myenv" zeigt alle)
  - **Vorteil**: Eine Variable weniger, nutzt Ansible-Standard
  - **Priorität**: Low (funktioniert aktuell, ist aber redundant)

- [ ] **Desktop-Hintergrund automatisiert setzen**
  - Unterschiedliche Bilder für private_mac vs. business_mac
  - Externe Monitore berücksichtigen (auch für künftig angesteckte Monitore)
  - Hintergrundbild evtl. zuerst herunterladen (wo speichern?)
  - Tool: `defaults write com.apple.desktop` oder AppleScript?

- [ ] **CMDB Update Funktion Review**
  - **Script**: `scripts/macupdate` (Zeilen 243-253)
  - **Funktion**: `update_cmdb()` ruft `~/iCloudDrive/Allgemein/bin/update_cmdb` auf
  - **Fragen**:
    - Was macht das CMDB-Script genau?
    - Ist es noch relevant/notwendig?
    - Sollte es in Ansible integriert werden?
    - Oder kann es entfernt werden?
  - **Kontext**: Optional aufgerufen am Ende von macupdate

## In Arbeit

_(Items die gerade bearbeitet werden)_

## Erledigt

- [x] **macOS Settings Migration zu Ansible** ✅ **ABGESCHLOSSEN (2025-12-24)**
  - **89 Settings migriert** von .macos zu Ansible defaults.yml (12 → 90 Settings, +658%)
  - **Phase 1 (71 Settings)**: System-Level (NSGlobalDomain, Dock, Finder, Screensaver, Screencapture)
  - **Phase 2 (18 Settings)**: App-Specific Stable (ActivityMonitor, TextEdit, Terminal, DiskUtility, SoftwareUpdate, TimeMachine)
  - **Cleanup durchgeführt**:
    - 264 orphaned comments entfernt
    - 33 broken settings dokumentiert (Safari/Mail domains existieren nicht mehr in macOS 26.2)
    - 51 obsolete/commented settings dokumentiert
    - .macos von 952 → 365 Zeilen reduziert (-62%)
  - **Tools erstellt** (8 Python/Bash Scripts):
    - `check-macos-settings.sh` - Validierung und Testing
    - `convert-macos-to-ansible.py` - Phase 1 Konvertierung
    - `convert-phase2-to-ansible.py` - Phase 2 Konvertierung
    - `merge-settings.py` - Duplikate-Erkennung
    - `remove-migrated-from-macos.py` - Cleanup Tool
    - `cleanup-macos.py` - Broken/Commented Settings Entfernung
    - `remove-orphaned-comments.py` - Comment Cleanup
    - `analyze-macos-script.sh` - Analyse Tool
  - **Dokumentation erstellt**:
    - `FINAL_MIGRATION_STATS_2025-12-24.md` - Komplette Statistiken
    - `BROKEN_DOMAIN_SETTINGS.md` - 33 broken Safari/Mail Settings
    - `COMMENTED_MACOS_SETTINGS.md` - 51 obsolete Settings
    - `macOS-26-manual-app-config.md` - Manuelle Checkliste (20 Settings)
    - `MACOS_MIGRATION_COMPLETED_2025-12-24.md` - Phase 1 Report
    - `MACOS_SETTINGS_AUDIT_2025-12-24.md` - Initial Audit
    - `MACOS_TO_ANSIBLE_MIGRATION.md` - Migration Plan
  - **Fixes durchgeführt**:
    - FXInfoPanesExpanded (complex dict) zurück zu .macos verschoben
    - lsregister -kill auskommentiert (deprecated)
    - universalaccess auskommentiert (Berechtigungsprobleme)
    - Spotlight config auskommentiert (System Protection)
    - addressbook auskommentiert (Berechtigungsprobleme)
    - Sleep timings korrigiert (displaysleep 5 < system sleep 15)
  - **Ergebnis**:
    - Ansible: 90 Settings (idempotent, versioniert)
    - .macos: 38 Settings (third-party apps, hardware-specific)
    - Manual: 20 Settings (Safari/Mail nicht automatisierbar)
    - Zero Duplicates, Clean Separation

- [x] **Drucker-Management implementiert** ✅ **ABGESCHLOSSEN (2025-12-24)**
  - **Konfigurationsdateien**:
    - `inventories/group_vars/macs/printers.yml` - Canon-Drucker für alle Macs
    - `inventories/group_vars/business_mac/printers.yml` - Follow2Print für Business-Macs
  - **Task-Datei**: `tasks/post/printers.yml` - CUPS/lpadmin Integration
  - **Features**:
    - Automatische Drucker-Installation via `./scripts/macapply --tags post`
    - Support für AirPrint/DNS-SD (Canon) und LPD-Drucker (Follow2Print)
    - Pull-Printing System mit User-Zuordnung (Follow2Print)
    - Konfigurierbare Drucker-Optionen (Duplex, Papierformat, etc.)
    - Standard-Drucker Festlegung
  - **Dokumentiert**: CLAUDE.md Abschnitt "Printer Management"
  - **Quick Fix**: `myenv` Variable in group_vars definiert (siehe TODO für Refactoring)

- [x] **init.sh robuster gemacht** ✅ **ABGESCHLOSSEN (2025-12-24)**
  - **Shellcheck Warnings behoben**: Alle 3 Warnings (SC2013, SC2086) behoben
  - **Pre-Flight Checks hinzugefügt**:
    - Admin-Rechte prüfen
    - Internet-Verbindung testen (ping github.com)
    - Disk Space prüfen (min. 10GB)
  - **Error Messages verbessert**: Jeder Fehler hat jetzt klare Beschreibung + Troubleshooting-Hinweis
  - **Code Quality**: Korrekte `while read` loops, konsistentes Quoting
  - **Ergebnis**: 0 shellcheck Warnings, robustere Bootstrap-Erfahrung

- [x] **Font-Management-System** ✅ **ABGESCHLOSSEN (2025-12-24)**
  - **Drei-Ebenen-System implementiert**:
    - `files/fonts/common/` - Fonts für alle Macs (committed)
    - `files/fonts/private/` - Fonts nur für private Macs (committed)
    - `~/iCloudDrive/Allgemein/fonts/licensed/` - Lizenzierte Fonts (nicht committed)
  - **Features**:
    - Automatische Installation via `./scripts/macapply --tags fonts`
    - Integration mit bestehendem Font-Download System (Basisschrift, Hack)
    - Font Cache Rebuild nach Installation
    - Flexible Konfiguration via `inventories/group_vars/macs/fonts.yml`
  - **Dokumentiert**: README in `files/fonts/README.md`
  - **Sicherheit**: Lizenzierte Fonts in `.gitignore`

- [x] **README Review** ✅ **ABGESCHLOSSEN (2025-12-24)**
  - **Problem**: README war grösstenteils von Upstream und nicht mehr aktuell
  - **Durchgeführte Änderungen**:
    - Installation Section komplett neu geschrieben (init.sh, macapply, macupdate)
    - Configuration Section: config.yml → Inventory-Hierarchie erklärt
    - Included Applications: Upstream-Liste → Verweis auf Brewfiles
    - Remote Mac Section: Inventory-Pfad korrigiert (inventories/macs.list)
    - Setup Guide: full-mac-setup.md → docs/NEW_MAC_SETUP.md
    - Testing/CI: Upstream CI → Fork CI dokumentiert
    - Tags korrigiert: sublime-text, sudoers, terminal entfernt (existieren nicht)
    - Dotfiles Link: geerlingguy → tuxpeople
  - **Ergebnis**: README ist jetzt Fork-spezifisch und aktuell

- [x] **Extra Packages Audit** ✅ **ABGESCHLOSSEN (2025-12-24)**
  - **Durchgeführt**: claude-code zu npm_packages hinzugefügt
  - **Dokumentiert in**: `inventories/group_vars/macs/additional-packages.yml`
  - **Ziel erreicht**: NPM-Pakete werden jetzt über Ansible verwaltet

- [x] **Python Version zentralisieren** ✅ **ABGESCHLOSSEN (2025-12-24)**
  - **Implementiert**: `.python-version` File erstellt
  - **Vorteil**: Single source of truth für Python-Version
  - **Location**: Root-Verzeichnis des Repos

- [x] **Dotfiles-Repo aufräumen** ✅ **ABGESCHLOSSEN (2025-10-24)**
  - **Entfernte Dateien**:
    - `.macos copy` - Veraltete Kopie gelöscht
    - `Brewfile copy` in business_mac/ - Duplikat entfernt
    - `brew.sh` - Obsolet (Homebrew via Ansible installiert)
    - `bootstrap.sh` - Obsolet (Dotfiles via Ansible gemanaged)
    - `all.sh` - Kombiniertes Script nicht mehr benötigt
    - `git.sh` - Repo-Cloning jetzt via ghorg
  - **Bonus**:
    - `Brewfile.lock.json` war bereits in .gitignore
    - ghorg config mit 1Password CLI Integration hinzugefügt
    - Ansible: `.config/ghorg` wird jetzt symlinked
    - Ansible: Sichergestellt dass `~/.config` Directory vor Symlink existiert
  - **Commits**:
    - dotfiles: `7493ef0` (Cleanup obsoleter Files)
    - mac-dev-playbook: `7c6c5ad`, `1b39062` (Dotfiles-Integration fixes)

_(Weitere abgeschlossene Items werden hier archiviert)_

---

**Hinweise**:

- Einfache Bulletpoints reichen aus
- Wichtige Details können in Klammern oder Sub-bullets ergänzt werden
- Bei Session-Start liest Claude diese Datei und arbeitet die Todos ab
