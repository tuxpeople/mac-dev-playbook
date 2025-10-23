# Pyenv Python Version Cleanup

## Übersicht

Dieser Ansible-Task entfernt automatisch alte/ungenutzte Python-Versionen von pyenv um Speicherplatz zu sparen.

## Konfiguration

Definiere in `inventories/group_vars/macs/general.yml` welche Versionen behalten werden sollen:

```yaml
python_versions_to_keep:
  - "3.11.8"  # Used by mac-dev-playbook (see scripts/macupdate)
  - "3.12.9"  # Add other versions you need
```

## Verwendung

Der Task läuft **nur** wenn explizit mit dem Tag `pyenv-cleanup` aufgerufen:

### Vollständiges Playbook

```bash
ansible-playbook plays/full.yml -i inventories -l $(hostname -s) --connection=local --tags pyenv-cleanup
```

### Update Playbook

```bash
ansible-playbook plays/update.yml -i inventories -l $(hostname -s) --connection=local --tags pyenv-cleanup
```

### Dry-Run (empfohlen vor erstem Durchlauf)

```bash
ansible-playbook plays/update.yml -i inventories -l $(hostname -s) --connection=local --tags pyenv-cleanup --check
```

## Was passiert?

1. **Erkennung**: Liste alle installierten Python-Versionen via `pyenv versions`
2. **Filter**: Vergleiche mit `python_versions_to_keep`
3. **Entfernung**: Lösche alle Versionen die NICHT in der Keep-Liste sind
4. **Report**: Zeige Zusammenfassung (gelöscht/behalten)

## Beispiel-Output

```
TASK [Display installed Python versions]
ok: [UMB-L3VWMGM77F] =>
  msg: Installed Python versions: ['3.10.12', '3.11.8', '3.12.9']

TASK [Remove old Python versions]
changed: [UMB-L3VWMGM77F] => (item=3.10.12)
skipping: [UMB-L3VWMGM77F] => (item=3.11.8)
skipping: [UMB-L3VWMGM77F] => (item=3.12.9)

TASK [Display cleanup summary]
ok: [UMB-L3VWMGM77F] =>
  msg: Cleanup complete. Kept versions: 3.11.8, 3.12.9. Removed 1 old version(s).
```

## Sicherheit

- ✅ Virtualenvs werden automatisch mit gelöscht (pyenv-Feature)
- ✅ Die aktuell konfigurierte Version (macupdate) wird nie gelöscht
- ✅ Task läuft nie automatisch (Tag: `never`)
- ✅ `--check` Mode unterstützt (Dry-Run)

## Wann sollte man das ausführen?

- ❌ **Nicht** bei jedem Update/Full-Run (zu aggressiv)
- ✅ **Manuell** wenn Speicherplatz knapp wird
- ✅ **Geplant** z.B. vierteljährlich
- ✅ **Nach** größeren Python-Upgrades

## Speicherplatzersparnis

Jede Python-Version benötigt ca. **100-200 MB**:

```bash
# Check current disk usage
du -sh ~/.pyenv/versions/*
```

Beispiel:
- 5 alte Versionen × 150 MB = **~750 MB** frei

## Troubleshooting

### "pyenv: command not found"

Stelle sicher dass pyenv installiert ist:
```bash
brew install pyenv pyenv-virtualenv
```

### "Version X is still in use"

Prüfe ob ein Virtualenv diese Version nutzt:
```bash
pyenv virtualenvs | grep "X.Y.Z"
```

### Manuelle Bereinigung

Falls Ansible-Task fehlschlägt, manuell:
```bash
pyenv uninstall 3.10.12
```

## Integration mit macupdate

Das `scripts/macupdate` Script nutzt die Version aus `python_versions_to_keep[0]`.

Synchronisiere beide wenn du die Python-Version änderst:

1. Update `scripts/macupdate`: `PYTHON_VERSION="3.12.9"`
2. Update `general.yml`: `python_versions_to_keep: ["3.12.9"]`
3. Run cleanup um alte zu entfernen

## Siehe auch

- `scripts/macupdate` - Python/Virtualenv Setup
- `tasks/pre/cleanup-deprecated-taps.yml` - Homebrew Tap Cleanup
- [pyenv Documentation](https://github.com/pyenv/pyenv)
