# Testing mit tart

Dieses Projekt nutzt [tart](https://tart.run) zum Testen von `init.sh` und der
Ansible-Playbooks in frischen macOS-VMs — ohne einen zweiten physischen Mac zu
benötigen.

> **Lizenz**: Apple erlaubt die Virtualisierung von macOS auf Apple-Hardware
> (M1/M2/M3). Nur Apple Silicon.

## Installation

```bash
brew install cirruslabs/cli/tart
```

Beim ersten Testlauf wird das Basis-Image (~24 GB) automatisch heruntergeladen
und als `base-mac` gespeichert. Folgeläufe klonen davon (copy-on-write, instant).

## Schnellstart

```bash
./scripts/tart-test
```

Das Script:

1. Prüft ob `base-mac` existiert, lädt es sonst herunter
2. Klont eine frische Test-VM
3. Startet die VM (mit UI-Fenster)
4. Wartet auf Boot und SSH-Erreichbarkeit
5. Öffnet eine SSH-Session mit dem fertig vorbereiteten Testbefehl
6. Löscht die VM nach dem Test automatisch

## Optionen

```bash
./scripts/tart-test --hostname mytest-mac   # Hostname ohne interaktiven Prompt
./scripts/tart-test --keep                  # VM nach Test behalten (für Inspektion)
BASE_VM=my-base ./scripts/tart-test         # Anderes Basis-Image verwenden
BOOT_WAIT=120 ./scripts/tart-test           # Längere Boot-Wartezeit (Sekunden)
```

## UI-Zugang

Beim `tart run` öffnet sich automatisch ein VM-Fenster mit der vollen macOS-UI.
Du kannst dort normal klicken, 1Password öffnen, System Settings aufrufen usw.

Für headless (kein Fenster):

```bash
tart run test-vm --no-graphics &
```

Für Screen Sharing (VNC) in einer laufenden VM:

```bash
# In der VM aktivieren (einmalig):
ssh admin@$(tart ip test-vm) \
  "sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
   -activate -configure -access -on -clientopts -setvnclegacy -vnclegacy yes \
   -clientopts -setvncpw -vncpw admin -restart -agent -privs -all"

# Danach verbinden:
open vnc://admin:admin@$(tart ip test-vm)
```

## Manuell testen

Ohne das Test-Script, Schritt für Schritt:

```bash
# 1. Basis-VM erstellen (einmalig)
tart clone ghcr.io/cirruslabs/macos-sequoia-base:latest base-mac

# 2. Test-VM klonen
tart clone base-mac test-run

# 3. VM starten (mit Repo-Verzeichnis geteilt)
tart run test-run --dir=repo:$(pwd) &

# 4. Warten bis gebootet, IP holen
tart ip test-run --wait 90

# 5. SSH rein (Passwort: admin)
ssh -o StrictHostKeyChecking=no admin@$(tart ip test-run)

# 6. In der VM: init.sh ausführen
/bin/bash '/Volumes/My Shared Files/repo/init.sh' --hostname test-mac

# 7. Aufräumen
tart delete test-run
```

## Einschränkungen

- **Phase 2 (1Password)** muss manuell in der VM-UI erledigt werden:
  1Password öffnen, einloggen, CLI-Integration aktivieren
- **Phase 3** (`macapply`) läuft dann ebenfalls in der VM — entweder via SSH
  oder direkt im VM-Terminal
- Vault-verschlüsselte Secrets (`ansible_become_pass` etc.) funktionieren erst
  nach Phase 2

## VM-Verwaltung

```bash
tart list                    # Alle VMs anzeigen
tart delete test-run         # VM löschen
tart ip test-run             # IP einer laufenden VM
tart run base-mac            # Basis-VM starten (nie für Tests modifizieren!)
```
