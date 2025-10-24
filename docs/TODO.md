# TODO List

Langfristige Aufgaben und Ideen für zukünftige Sessions.

## Zu erledigen

- [ ] **Bootstrap Scripts Review & Konsolidierung**
  - Analysieren: `init.sh` (85+ Zeilen, komplex) und `init_light.sh` (7 Zeilen, nur pip/ansible-galaxy)
  - `init.sh`: Klont Repo, lädt iCloud-Dateien, installiert CLI-Tools, fragt nach Hostname
  - `init_light.sh`: Installiert nur Python-Requirements und Ansible-Galaxy-Roles
  - Prüfen: Funktionieren beide noch? Sind Abhängigkeiten aktuell?
  - Vergleichen: Mit `scripts/macupdate` (ähnliche Funktionalität?)
  - Entscheiden:
    - Beide behalten oder zu `scripts/bootstrap.sh` konsolidieren?
    - iCloud-Abhängigkeiten noch zeitgemäß?
  - Dokumentieren: README.md mit Bootstrap-Anleitung erweitern

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
