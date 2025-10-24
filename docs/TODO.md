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

- [ ] **Dotfiles vs. Ansible Repo - Verantwortlichkeiten klären** ✅ **ANALYSIERT**
  - **Status**: Vollständige Analyse erstellt in `docs/analysis/DOTFILES_ANSIBLE_ANALYSIS.md`
  - **Findings**:
    - `.macos` (952 Zeilen!): Wird von `tasks/osx.yml` ausgeführt, sollte zu Ansible-Tasks werden
    - `Brewfiles`: Liegen im Dotfiles-Repo, werden aber nur von Ansible genutzt
    - Echte Dotfiles: Sollten im Dotfiles-Repo bleiben (Shell, Git, Vim configs)
  - **Empfehlung**: 3-Phasen-Migration
    1. Brewfiles ins Ansible-Repo verschieben (schnell & einfach)
    2. `.macos` zu `community.general.osx_defaults` Tasks konvertieren (aufwändig)
    3. Dotfiles-Repo aufräumen (Duplikate löschen)
  - **Nächster Schritt**: Entscheidung treffen & mit Phase 1 (Brewfiles) starten
- [ ] Das Readme ist ja grösstenteils von Upstream. Gibt es darin Dinge, die für uns nicht gelten oder hat es allenfalls Dinge die man noch dokumentieren müsste darin?

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
