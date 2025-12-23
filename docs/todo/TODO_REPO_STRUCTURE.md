# TODO: Repository Struktur & Organisation Review

**Erstellt**: 2025-10-23
**Priorität**: MEDIUM
**Aufwand**: ~2 Stunden
**Fokus**: Lokale Änderungen überprüfen, Upstream-Kompatibilität maximieren

---

## Zielsetzung

1. **Lokale Änderungen evaluieren**: Sind alle custom Files/Features noch sinnvoll?
2. **Struktur optimieren**: Bessere Organisation für Wartbarkeit
3. **Upstream-Kompatibilität**: Minimale Abweichung vom Original-Repo
4. **Dokumentation konsolidieren**: Markdown-Dateien organisieren

---

## 1. Scripts & Executables Review

### Zu prüfen:
- [ ] Alle Dateien im Root-Verzeichnis identifizieren die eigentlich in `scripts/` gehören
- [ ] Shell-Scripts ohne `.sh` Extension (init*, setup*, etc.)
- [ ] Python-Scripts die als Helfer dienen
- [ ] Obsolete Scripts identifizieren und entfernen

### Bekannte Scripts:
- `scripts/macupdate` - ✅ Bereits im scripts/ Ordner
- Root-Level Scripts? (noch zu identifizieren)

### Fragen:
- Gibt es `init*` oder `setup*` Scripts im Root?
- Gibt es alte/ungenutzte Scripts?

---

## 2. Dokumentation & Markdown Files

### Aktuelle Struktur (Root-Level):
```
CLAUDE.md
DEPENDENCY_STRATEGY.md
DEPENDABOT_TO_RENOVATE_MIGRATION.md
FORK_ANALYSIS.md
IMPROVEMENTS.md
README.md
RENOVATE_SETUP.md
SESSION_STATUS.md
SESSION_SUMMARY.md
TODO_ANALYSIS.md
TODO_REPO_STRUCTURE.md (dieses Dokument)
UPSTREAM_SYNC.md (?)
```

### Vorgeschlagene Struktur:
```
README.md                          # Bleibt im Root (Hauptdokumentation)
CLAUDE.md                          # Bleibt im Root (wichtig für Claude Code)

docs/
  ├── sessions/
  │   ├── SESSION_STATUS.md        # Aktuelle Session
  │   ├── SESSION_SUMMARY.md       # Session 1
  │   └── SESSION_HISTORY.md       # Archiv aller Sessions
  │
  ├── maintenance/
  │   ├── DEPENDENCY_STRATEGY.md
  │   ├── RENOVATE_SETUP.md
  │   └── DEPENDABOT_MIGRATION.md  # Umbenannt
  │
  ├── analysis/
  │   ├── FORK_ANALYSIS.md
  │   ├── IMPROVEMENTS.md
  │   └── TODO_ANALYSIS.md
  │
  └── todo/
      └── REPO_STRUCTURE.md        # Dieses Dokument
```

### Zu entscheiden:
- [ ] Soll diese Struktur implementiert werden?
- [ ] Welche Dateien müssen im Root bleiben für Upstream-Kompatibilität?
- [ ] Gibt es obsolete Markdown-Dateien?

---

## 3. Lokale Änderungen & Custom Features Review

### Custom Roles (bereits analysiert):
- ✅ `roles/ansible-mac-update` - Custom, wird verwendet
- ✅ `roles/munki_update` - Custom, wird verwendet

### Zu prüfen:

#### Tasks & Playbooks:
- [ ] `tasks/pre/*` - Welche sind custom vs. upstream?
- [ ] `tasks/post/*` - Alle Custom-Tasks evaluieren:
  - Werden sie noch verwendet?
  - Sind sie noch relevant?
  - Könnten sie zu Rollen konsolidiert werden?
- [ ] `plays/*` - Custom Playbooks vs. Upstream

#### Inventory & Configuration:
- [ ] Sind alle Host-Vars noch aktuell?
- [ ] Gibt es obsolete Group-Vars?
- [ ] Secrets richtig verwaltet?

#### GitHub Workflows:
- [ ] `.github/workflows/*` - Custom vs. Upstream
- [ ] Sind alle CI-Jobs noch relevant?
- [ ] Optimierungspotential?

---

## 4. Upstream Sync Strategy

### Bidirektionale Review:

#### Upstream → Fork (bereits in FORK_ANALYSIS.md):
- MAS conditional fix
- Cowsay removal
- dotfiles_repo_version updates

#### Fork → Upstream (NEU - zu prüfen):
- [ ] Welche lokalen Improvements könnten Upstream beitragen?
- [ ] Security-Fixes (C6, C7, C8) relevant für Upstream?
- [ ] macupdate Script-Konzept für Upstream interessant?
- [ ] Renovate-Setup als Contribution?

**Frage**: Sollten wir Pull Requests zum Upstream erstellen?

---

## 5. Optimierungspotentiale

### Performance:
- [ ] Können Tasks parallelisiert werden?
- [ ] Gibt es redundante Operations?
- [ ] Caching-Möglichkeiten?

### Sicherheit:
- [ ] Alle Secrets aus Repos entfernt?
- [ ] Sichere Defaults überall?
- [ ] Sudo-Handling optimal?

### Wartbarkeit:
- [ ] Code-Duplikation reduzieren
- [ ] Bessere Modularisierung
- [ ] Dokumentation vervollständigen

---

## 6. Konkrete Aktionen (Priorisiert)

### High Priority:
1. [ ] Root-Level Scripts identifizieren und nach `scripts/` verschieben
2. [ ] Obsolete Dateien/Features finden und entfernen
3. [ ] Markdown-Struktur evaluieren (docs/ Ordner ja/nein?)

### Medium Priority:
4. [ ] Alle `tasks/post/*` durchgehen: Noch verwendet?
5. [ ] Custom Playbooks dokumentieren
6. [ ] Inventory aufräumen

### Low Priority:
7. [ ] Upstream Contribution evaluieren
8. [ ] Performance-Optimierungen
9. [ ] Weitere Code-Qualität-Verbesserungen

---

## 7. Risiken & Überlegungen

### Upstream-Kompatibilität:
- **Risiko**: Zu viel Umstrukturierung → schwierig Updates zu mergen
- **Mitigation**: Änderungen dokumentieren, Merge-Strategy festlegen

### Breaking Changes:
- **Risiko**: Scripts/Paths verschieben → bestehende Workflows brechen
- **Mitigation**: Symlinks für Backward-Compatibility, Migration-Guide

### Time Investment:
- **Risiko**: Zu viel Zeit für Organisation statt Features
- **Mitigation**: Fokus auf Quick Wins, iteratives Vorgehen

---

## 8. Nächste Schritte

1. **Quick Scan durchführen**:
   ```bash
   # Scripts im Root finden
   find . -maxdepth 1 -type f -executable

   # Markdown-Dateien zählen
   ls -1 *.md | wc -l

   # Ungenutzte Tasks finden
   grep -r "include_tasks\|import_tasks" plays/ | sort -u
   ```

2. **Entscheidung treffen**: docs/ Struktur ja/nein?

3. **Schrittweise umsetzen**: Eine Kategorie nach der anderen

---

## Notizen

- Token-Budget beachten (aktuell: ~67k/200k verwendet)
- Große Umstrukturierungen in separatem Branch testen
- Session-Dokumentation aktualisieren
- CLAUDE.md auf dem neuesten Stand halten

---

**Status**: 🟡 TODO - Noch nicht gestartet
**Nächste Review**: Nach Abschluss CRITICAL Issues oder in nächster Session
