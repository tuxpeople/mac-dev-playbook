# TODO List

Langfristige Aufgaben und Ideen für zukünftige Sessions.

## Zu erledigen

- [x] **Tasks Reorganisation - Separation of Concerns** ✅ **ABGESCHLOSSEN (2025-12-26)**
  - **Phase 1**: ✅ Dock-Konfiguration ausgelagert (Commit `0f3e90a`, Session 5)
  - **Phase 2**: ✅ various-settings.yml reorganisiert (Session 5)
  - **Durchgeführte Änderungen**:
    - ✅ `tasks/finder.yml` erstellt - Finder-spezifische Settings (40 Zeilen)
    - ✅ `tasks/system.yml` erstellt - System-Level Settings (25 Zeilen)
    - ✅ `tasks/maintenance.yml` erstellt - Maintenance Tasks (31 Zeilen)
    - ✅ Dock restart zu `tasks/dock.yml` verschoben
    - ✅ `various-settings.yml` reduziert: 113 → 38 Zeilen (Orchestrator)
  - **Neue Tags verfügbar**:
    - `--tags finder` - Nur Finder-Settings
    - `--tags system` - Nur System-Settings (Touch ID, SSH, Wallpaper)
    - `--tags maintenance` - Nur Maintenance Tasks
    - `--tags dock` - Dock inkl. Dock restart
  - **Ergebnis**:
    - Bessere Wartbarkeit (Separation of Concerns)
    - Granulare Tags für schnelles Testen
    - Klarere Struktur - jede Datei hat einen Zweck
  - **Hinzugefügt**: 2025-12-26 (Session 5)

- [x] **LaunchAgents Tasks Review** ✅ **ABGESCHLOSSEN (2025-12-31)**
  - **Phase 1**: Private Mac Review ✅ (Commits `6fb846c`, `6060075`)
    - Cleanup: 30 → 6 agents (-80%)
    - Task verbessert: Bessere Idempotenz
    - Per-group Konfiguration: base + private_mac
  - **Phase 2**: Business Mac Review ✅ (2025-12-31)
    - Systematische Prüfung aller LaunchAgents/Daemons auf Business Mac
    - 25 Agents zum Deaktivieren markiert (Microsoft, Citrix, VMware, GoToMeeting, etc.)
    - OneDriveLauncher und Ollama bewusst aktiv gelassen
    - Login Items geprüft (7 Apps - 5 behalten, 2 manuell entfernen)
  - **Hinzugefügt**: 2025-12-25 (Session mit saga setup)
  - **Abgeschlossen**: 2025-12-31 (Session 6)

- [x] **Dock Items Review & Cleanup** ✅ **ABGESCHLOSSEN (2025-12-31)**
  - **Durchgeführt**:
    - ✅ `private_mac/dock.yml`: Launchpad und Todoist entfernt (Commit `32cf52d`)
    - ✅ `business_mac/dock.yml`: Alle 17 Apps geprüft - alle existieren
    - ✅ `macs/dock.yml`: Bereits sauber (dockitems_persist leer)
  - **Ergebnis**: Alle Dock-Konfigurationen sind aktuell und korrekt
  - **Hinzugefügt**: 2025-12-25 (Session mit saga setup)
  - **Abgeschlossen**: 2025-12-31 (Session 6)

- [ ] **"Fokus arbeiten" Shortcuts Deployment für Business Macs**
  - **Was**: Apple Shortcuts Automatisierung die beim Login den Fokus auf "arbeiten" setzt
  - **Aktuell**: Nur manuell erstellt auf einem Business Mac (UMB-L3VWMGM77F)
  - **Ziel**: Automatisches Deployment via Ansible für neue Business Macs
  - **Umsetzung**:
    - Shortcut als `.shortcut` Datei exportieren
    - In Repository speichern (`files/shortcuts/business_mac/`)
    - Ansible Task erstellen (Copy + Import via shortcuts CLI oder AppleScript)
    - Bei neuem Business Mac Setup automatisch installieren
  - **Priorität**: Medium (Nice-to-have)
  - **Siehe auch**: `/tmp/login_items_decisions.md` (Details)
  - **Hinzugefügt**: 2025-12-31 (Session 6)

- [ ] **Startup Items Review auf Private Macs**
  - **Was**: Umfassende Startup/Login Items Analyse auf Private Macs (odin, thor)
  - **Hintergrund**: Business Mac Review (Session 6) war sehr aufschlussreich
  - **Durchzuführen**:
    - Scan aller LaunchAgents/LaunchDaemons (via launchctl list)
    - Login Items prüfen (System Settings via osascript)
    - Background Task Management prüfen (sfltool dumpbtm)
    - Entscheidung für jeden Agent/Daemon: behalten oder deaktivieren
  - **Ziel**: Optimierte Startup-Performance auf Private Macs
  - **Methode**: Gleiche systematische Vorgehensweise wie Business Mac
  - **Priorität**: Medium
  - **Siehe auch**: Business Mac Review (Session 6, Commit a567c49)
  - **Hinzugefügt**: 2025-12-31 (Session 6)

- [ ] **Munki-installierte Apps Review & Automatisierung**
  - **Was**: Prüfen welche Apps aktuell via Munki installiert sind
  - **Ziel**: Apps für automatische Installation auf neuen Geräten konfigurieren
  - **Durchzuführen**:
    - Liste aller Munki-managed Apps erstellen (`/usr/local/munki/munki-installed`)
    - Prüfen welche Apps auch auf neuen Macs gewünscht sind
    - Entscheiden: Munki vs. Homebrew vs. Manual
    - Ggf. Munki Manifests in Ansible integrieren
  - **Hintergrund**: Munki managed aktuell Apps, aber unklar welche
  - **Priorität**: Low-Medium
  - **Hinzugefügt**: 2025-12-31 (Session 6)

- [ ] **Externe Abhängigkeiten Review & Entkopplungsstrategie**
  - **Aktuelle Abhängigkeiten**:
    - **iCloud Drive**: Dotfiles (ssh_keys, ssh_config, bin-scripts), filelists, licensed fonts
    - **1Password**: Vault password, GitHub token, Hazel license, ghorg integration
    - **macOS Keychain**: Vault password (lokal, nicht synced), SSH key passphrases
  - **Fragen zu klären**:
    - Welche Abhängigkeiten sind zwingend notwendig?
    - Welche können optional/fallback gemacht werden?
    - Was passiert wenn iCloud nicht verfügbar ist? (init.sh skip vs. fail)
    - Sollte 1Password zwingend sein oder gibt es Alternativen?
    - Keychain: Automatisierung möglich oder immer manuell?
  - **Potentielle Verbesserungen**:
    - iCloud: Timeouts und Fallbacks verbessern (bereits teilweise implementiert)
    - 1Password: Dokumentieren was manuell gemacht werden muss wenn nicht verfügbar
    - Secrets: Alternative Storage-Optionen evaluieren (z.B. nur Ansible Vault)
    - Dotfiles: Kritische vs. optionale Files trennen
  - **Ziel**: Setup robuster machen, weniger Single Points of Failure

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
    - [x] README.md: Bootstrap-Sektion erweitern (Wann welches Script?) ✅ **ERLEDIGT (Commit `24e3504`, 2025-12-25)**
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
  - **Phase 3: Dotfiles-Repo aufräumen** ✅ **ERLEDIGT (2025-12-31)**
    - ✅ .macos.backup* Dateien entfernt (manuell)
    - ✅ Nur echte Dotfiles behalten

- [ ] **myenv Variable Refactoring** ⚠️ **NICHT KRITISCH - FUNKTIONIERT**
  - **Status**: Analysiert (2025-12-26) - Komplexer als erwartet
  - **Aktuell**: Variable `myenv` wird doppelt definiert (group_vars + runtime fact)
  - **Warum redundant**: Hosts sind bereits in Inventory-Gruppen (business_mac/private_mac) zugeordnet
  - **Warum kompliziert**:
    - Verwendet `group_by: key=myenv` für dynamische Gruppierung
    - `post.yml` nutzt `{{ myenv }}-settings.yml` für dynamische Includes
    - Pattern-Matching in additional-facts.yml als Absicherung
  - **Ziel (wenn durchgeführt)**: Ersetzen durch Ansible's eingebaute `group_names` Variable
  - **Aufwand**: 15-20 Min, braucht Tests
  - **Vorteil**: Eine Variable weniger, nutzt Ansible-Standard
  - **Priorität**: Low (funktioniert aktuell, technische Schuld aber nicht kritisch)
  - **Entscheidung**: Später angehen, wenn mehr Zeit oder bei größerem Refactoring

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
