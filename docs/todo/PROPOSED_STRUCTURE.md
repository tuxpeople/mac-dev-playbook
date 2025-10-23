# Vorgeschlagene Repository-Struktur

## Aktueller Status

### Root-Level (47 Dateien/Ordner)
- **16 Markdown-Dateien** (zu viel!)
- 2 Scripts: `init.sh`, `init_light.sh`
- Diverse Ansible-Dateien (Playbooks, Config, etc.)

### Problem
- Unübersichtlich: Zu viele Files im Root
- Vermischt: Dokumentation zwischen Code
- Upstream-Kompatibilität: Zusätzliche Dateien erschweren Merges

---

## Vorgeschlagene Struktur

```
mac-dev-playbook/
├── README.md                    # BLEIBT (Hauptdokumentation)
├── CLAUDE.md                    # BLEIBT (wichtig für Claude Code)
├──full-mac-setup.md            # BLEIBT? (Quick Start - diskutieren)
│
├── scripts/                     # ✅ Existiert bereits
│   └── macupdate                # ✅ Bereits verschoben
│
├── docs/                        # 📁 Dokumentations-Hub
│   │
│   ├── sessions/                # Session-Dokumentation
│   │   ├── SESSION_STATUS.md         # ← aus Root
│   │   ├── SESSION_SUMMARY.md        # ← aus Root
│   │   └── SECRETS_FIXES_APPLIED.md  # ← aus Root
│   │
│   ├── maintenance/             # Wartungs-Anleitungen
│   │   ├── DEPENDENCY_STRATEGY.md           # ← aus Root
│   │   ├── RENOVATE_SETUP.md                # ← aus Root
│   │   ├── DEPENDABOT_MIGRATION.md          # ← aus Root (umbenannt)
│   │   └── PYENV_CLEANUP.md                 # ✅ Bereits hier
│   │
│   ├── analysis/                # Code/Issue-Analysen
│   │   ├── FORK_ANALYSIS.md              # ← aus Root
│   │   ├── IMPROVEMENTS.md               # ← aus Root
│   │   └── TODO_ANALYSIS.md              # ← aus Root
│   │
│   ├── guides/                  # How-To Guides
│   │   ├── MACOS_DEFAULTS_GUIDE.md       # ← aus Root
│   │   ├── 1PASSWORD_SSH_STRATEGY.md     # ← aus Root
│   │   ├── MUNKI_IMPROVEMENTS.md         # ← aus Root
│   │   └── FULL_MAC_SETUP.md             # ← aus Root (falls verschoben)
│   │
│   └── todo/                    # Offene Tasks/Planung
│       └── REPO_STRUCTURE.md             # ← aus Root (umbenannt)
│
├── plays/                       # ✅ Wie bisher
├── tasks/                       # ✅ Wie bisher
├── roles/                       # ✅ Wie bisher
├── inventories/                 # ✅ Wie bisher
└── ...                          # Rest unverändert
```

---

## Migration Plan

### Phase 1: Dokumentation verschieben (Einfach, kein Funktionscode)

**Vorteile:**
- ✅ Sauberer Root
- ✅ Bessere Organisation
- ✅ Einfacher für neue Nutzer
- ✅ Kein Impact auf Ansible

**Risiken:**
- ⚠️ Links in Dokumentation brechen
- ⚠️ Externe Bookmarks brechen

**Mitigation:**
- Symlinks für wichtige Dateien (optional)
- GitHub automatisches Redirect für alte URLs
- Update alle internen Links

### Phase 2: Scripts konsolidieren (Optional)

**Aktuell:**
- `init.sh` - Im Root
- `init_light.sh` - Im Root
- `scripts/macupdate` - Bereits in scripts/

**Vorschlag:**
```bash
# Option A: Alles nach scripts/
scripts/
  ├── init.sh
  ├── init_light.sh
  └── macupdate

# Option B: Symlinks für Convenience
./init.sh -> scripts/init.sh  # Symlink für Backwards-Compat
```

---

## Upstream-Kompatibilität

### Dateien die Upstream NICHT hat (sicher zu verschieben):

**Session-Docs:**
- SESSION_STATUS.md
- SESSION_SUMMARY.md
- SECRETS_FIXES_APPLIED.md

**Maintenance:**
- DEPENDENCY_STRATEGY.md
- RENOVATE_SETUP.md
- DEPENDABOT_TO_RENOVATE_MIGRATION.md

**Analysis:**
- FORK_ANALYSIS.md
- TODO_ANALYSIS.md
- TODO_REPO_STRUCTURE.md

**Guides:**
- MACOS_DEFAULTS_GUIDE.md
- 1PASSWORD_SSH_STRATEGY.md
- MUNKI_IMPROVEMENTS.md

**Scripts:**
- `scripts/macupdate` (bereits verschoben)

### Dateien die Upstream HAT (vorsichtig!):

- `README.md` - NICHT verschieben (Upstream modifiziert diese)
- `IMPROVEMENTS.md` - Prüfen ob Upstream-Äquivalent existiert
- `full-mac-setup.md` - Prüfen ob Upstream-Äquivalent existiert

### Upstream-Vergleich benötigt:

```bash
# Prüfe was Upstream im Root hat
git fetch upstream
git ls-tree -r --name-only upstream/master | grep "\.md$"
```

---

## Entscheidungsmatrix

| Datei | Root behalten? | Wohin? | Begründung |
|-------|---------------|--------|------------|
| README.md | ✅ JA | - | Standard, Upstream |
| CLAUDE.md | ✅ JA | - | Wichtig für Claude Code |
| full-mac-setup.md | ❓ | docs/guides/ | Quick Start, evtl. im Root lassen |
| SESSION_*.md | ❌ NEIN | docs/sessions/ | Session-spezifisch |
| *_STRATEGY.md | ❌ NEIN | docs/maintenance/ | Maintenance-Docs |
| *_ANALYSIS.md | ❌ NEIN | docs/analysis/ | Analyse-Dokumente |
| *_GUIDE.md | ❌ NEIN | docs/guides/ | How-To Guides |
| TODO_*.md | ❌ NEIN | docs/todo/ | Planning Docs |

---

## Vorgeschlagene Aktion

### Minimal (Quick Win):
1. Erstelle `docs/` Unterordner-Struktur
2. Verschiebe Session-Docs nach `docs/sessions/`
3. Verschiebe Maintenance-Docs nach `docs/maintenance/`
4. Update `CLAUDE.md` mit neuen Pfaden

**Aufwand:** ~15 Minuten
**Impact:** Übersichtlicherer Root

### Moderat (Empfohlen):
Minimal +
5. Verschiebe Analysis-Docs nach `docs/analysis/`
6. Verschiebe Guides nach `docs/guides/`
7. Update alle internen Links

**Aufwand:** ~30 Minuten
**Impact:** Professionelle Struktur

### Vollständig:
Moderat +
8. Verschiebe init*.sh nach `scripts/`
9. Erstelle Symlinks für Backwards-Compatibility
10. Update alle GitHub Wiki/Issues mit neuen Links

**Aufwand:** ~1 Stunde
**Impact:** Perfekte Organisation

---

## Empfehlung

**Starte mit MODERAT:**

Gründe:
- ✅ Großer Mehrwert bei moderatem Aufwand
- ✅ Keine Breaking Changes (init.sh bleibt im Root)
- ✅ Bessere Maintainability
- ✅ Upstream-Merges einfacher

**NICHT empfohlen jetzt:**
- ❌ Große Refactorings (z.B. init.sh verschieben)
- ❌ Änderungen an Upstream-Dateien (README.md)

---

## Nächste Schritte

1. **Entscheidung:** Minimal, Moderat oder Vollständig?
2. **Backup:** Git stash/branch für Rollback
3. **Durchführung:** Dateien verschieben mit `git mv`
4. **Links aktualisieren:** Interne Referenzen fixen
5. **Testen:** Ansible Playbooks prüfen (sollten nicht betroffen sein)
6. **Commit:** Strukturierte Commit-Message
7. **Update:** CLAUDE.md und README.md

---

**Status:** 🟡 Vorschlag - Wartet auf Entscheidung
**Erstellt:** 2025-10-23
**Token-Budget:** ~104k/200k (noch genug für Umsetzung!)
