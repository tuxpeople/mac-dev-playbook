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

- [ ] **Dotfiles vs. Ansible Repo - Verantwortlichkeiten klären**
  - **Problem**: Aktuell im Dotfiles-Repo `/Volumes/development/github/tuxpeople/dotfiles`:
    - `.macos` (43KB) - macOS defaults Einstellungen
    - `brew.sh` - Homebrew installation script
    - `machine/business_mac/Brewfile` - Homebrew packages (Business)
    - `machine/private_mac/Brewfile` - Homebrew packages (Private)
    - Echte Dotfiles: `.bashrc`, `.bash_profile`, `.aliases`, `.functions`, etc.
  - **Analyse**:
    - Was gehört ins Ansible-Repo (System-Provisionierung)?
      - Brewfiles? (werden von ansible-mac-update genutzt)
      - `.macos` defaults? (überschneidet sich mit `tasks/osx.yml`?)
    - Was bleibt im Dotfiles-Repo (User-Config)?
      - Shell-Konfiguration (.bashrc, .bash_profile, etc.)
      - Git-Config (.gitconfig)
      - Vim/Editor-Configs
  - **Aktionen**:
    - Inventarisieren: Welche Dateien werden von Ansible genutzt?
    - Vergleichen: `.macos` vs. `tasks/osx.yml` (Duplikate?)
    - Migrieren: Ansible-spezifische Configs hierher
    - Dokumentieren: Klare Trennung der Verantwortlichkeiten
    - Updaten: `geerlingguy.dotfiles` Role-Konfiguration anpassen

- [ ] **Dotfiles-Repo aufräumen**
  - **Veraltete/Duplikat-Dateien identifiziert**:
    - `.macos copy` - Duplikat von `.macos`?
    - `Brewfile copy` in business_mac/ - Warum Kopie?
    - `brew.sh` - Verwendet veraltete Homebrew-Installation (ruby -e curl)
    - `Brewfile.lock.json` - Sollte in .gitignore?
  - **Aktionen**:
    - Prüfen: Welche Dateien werden tatsächlich genutzt?
    - Aufräumen: Duplikate und veraltete Scripts entfernen
    - Modernisieren: `brew.sh` auf aktuelle Homebrew-Installation updaten (oder ganz löschen, wenn Ansible das übernimmt)
    - Git: Alte Dateien aus Historie entfernen (falls sensible Daten)?
    - Dokumentieren: README.md im Dotfiles-Repo verbessern

## In Arbeit

_(Items die gerade bearbeitet werden)_

## Erledigt

_(Abgeschlossene Items werden hier archiviert)_

---

**Hinweise**:

- Einfache Bulletpoints reichen aus
- Wichtige Details können in Klammern oder Sub-bullets ergänzt werden
- Bei Session-Start liest Claude diese Datei und arbeitet die Todos ab
