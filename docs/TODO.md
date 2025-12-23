# TODO List

Langfristige Aufgaben und Ideen für zukünftige Sessions.

## Zu erledigen

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
    - [ ] README.md: Bootstrap-Sektion erweitern (Wann welches Script?)
    - [ ] iCloud-Dependency untersuchen: Was steht in filelists?
    - [ ] Optional: Konsolidierung evaluieren (siehe Analyse Option 2)

- [ ] **Dotfiles vs. Ansible Repo - Phase 2 & 3** 🔄 **PHASE 1 ABGESCHLOSSEN (2025-12-22)**
  - **Phase 1: Brewfiles verschieben** ✅ **ERLEDIGT**
    - Brewfiles von dotfiles nach `files/brewfile/business_mac/` und `private_mac/`
    - Config aktualisiert in `brew.yml` (beide Groups)
    - Wichtige Erkenntnis: Brewfiles dürfen NICHT in `group_vars/` (wird als YAML geparst)
    - Dokumentiert in `docs/BREWFILE_MIGRATION.md`
    - Siehe auch: `docs/analysis/REPOSITORY_REVIEW.md` Priority 2
  - **Phase 2: .macos konvertieren** (offen)
    - `.macos` (952 Zeilen) zu `community.general.osx_defaults` Tasks konvertieren
    - Aufwändig, aber macht Settings transparenter
  - **Phase 3: Dotfiles-Repo aufräumen** (offen)
    - Duplikate entfernen
    - Nur echte Dotfiles behalten

- [ ] Das Readme ist ja grösstenteils von Upstream. Gibt es darin Dinge, die für uns nicht gelten oder hat es allenfalls Dinge die man noch dokumentieren müsste darin?

- [ ] **Drucker konfigurieren**
  - Drucker-Setup automatisieren (falls möglich)
  - Welche Drucker werden genutzt? (Business vs. Private)
  - Gibt es spezifische Drucker-Einstellungen die persistiert werden müssen?

- [ ] **Extra Packages Audit**
  - Feststellen, ob manuell npm, pip, gem, composer Pakete installiert wurden
  - Check: `npm list -g --depth=0`, `pip list`, `gem list`, `composer global show`
  - Gefundene Pakete in `inventories/group_vars/macs/additional-packages.yml` eintragen
  - Ziel: Reproduzierbare Package-Installation über Ansible

- [ ] **macOS Settings Audit - Funktionalität**
  - Durchgehen, welche der Mac Settings (`defaults write...` etc.) auf aktuellen macOS noch funktionieren
  - File: `~/.macos` (952 Zeilen) bzw. die entsprechenden `tasks/osx.yml` Tasks
  - Deprecated Settings identifizieren und entfernen
  - Neue macOS-Versionen können Settings ändern/entfernen

- [ ] **macOS Settings Audit - Manuelle Änderungen**
  - Durchgehen, welche Mac Settings manuell geändert wurden (nicht in Ansible)
  - Vergleich: Aktuelle System-Settings vs. Ansible-Config
  - Manuelle Änderungen dokumentieren und in Ansible übernehmen
  - Tool: `defaults read` für aktuelle Werte

- [ ] **macOS Settings - Automatisierung erweitern**
  - Herausfinden, welche weiteren Settings automatisiert werden könnten
  - Kandidaten: System Preferences die regelmäßig manuell gesetzt werden
  - Prüfen: Gibt es neue Settings in neueren macOS-Versionen?
  - Optional: Konvertierung von `.macos` zu `community.general.osx_defaults` Tasks

- [ ] **Desktop-Hintergrund automatisiert setzen**
  - Unterschiedliche Bilder für private_mac vs. business_mac
  - Externe Monitore berücksichtigen (auch für künftig angesteckte Monitore)
  - Hintergrundbild evtl. zuerst herunterladen (wo speichern?)
  - Tool: `defaults write com.apple.desktop` oder AppleScript?

- [ ] **Zusätzliche Fonts für Private Macs**
  - Problem: Fonts dürfen nicht öffentlich im Internet stehen (Lizenz?)
  - Lösungsoptionen:
    - iCloud Drive als Quelle (analog zu "Open Umb.app" in business_mac-settings.yml)?
    - Private Git Repo (z.B. GitHub private)?
    - Lokal vorhandene Fonts prüfen und nur kopieren wenn vorhanden?
  - Welche Fonts werden benötigt?

## In Arbeit

_(Items die gerade bearbeitet werden)_

## Erledigt

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
