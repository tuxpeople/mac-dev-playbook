# Munki Configuration Improvements

**Erstellt**: 2025-10-22

## Aktuelle Situation

### Was ist bereits gut gelöst ✅

1. **Group-basierte Munki Aktivierung**:
   - `business_mac/main.yml`: `munki_update: true`
   - `private_mac/main.yml`: `munki_update: false`
   - `plays/update.yml`: `when: munki_update` auf der Role

2. **Check-Only Mode**:
   - `macs/munki.yml`: `munki_check_only: true` (default)

3. **Device Type Detection**:
   - `additional-facts.yml` setzt `myenv` basierend auf Hostname pattern
   - Business devices: `ws.*` oder `UMB.*`
   - Default: `private_mac`

### Was verbessert werden sollte 🔧

## Problem 1: Munki Conditional könnte klarer sein

**Aktuell** in `plays/update.yml`:

```yaml
- role: munki_update
  when: munki_update  # Variable name = role name (verwirrend)
```

**Empfohlene Verbesserung**:

```yaml
- role: munki_update
  when: munki_update | default(false) | bool
  tags: ['munki']
```

**Warum besser**:

- Expliziter `| bool` cast (Best Practice)
- Default auf `false` wenn nicht definiert (fail-safe)
- Tag für selektive Ausführung

---

## Problem 2: Install vs Check Mode - Flexibilität fehlt

**Aktuell**:

- `munki_check_only: true` ist global in `macs/munki.yml`
- Alle Geräte machen nur Check, keine Installation

**User-Anforderung**:
> "Ich möchte eine Option damit ich auf bestimmten Geräten aktivieren kann, dass Munki Updates installiert werden sollen"

### Lösung: Multi-Level Configuration

#### Ebene 1: Global Default (macs/munki.yml)

```yaml
# Global defaults für alle Macs
munki_check_only: true  # Safe default - nur checken
munki_update: false     # Default OFF (wird von groups überschrieben)

# Optional: Munki package filtering
munki_skip_if_present: []
# munki_skip_if_present:
#   - "Microsoft Teams"  # Skip update if Teams is in pending list
```

#### Ebene 2: Group Level (business_mac/main.yml, private_mac/main.yml)

**business_mac/main.yml**:

```yaml
# Business Macs haben Munki
munki_update: true

# Default: Nur checken (safe)
munki_check_only: true

# Optional: Business-spezifische Skip-Pakete
munki_skip_if_present:
  - "Microsoft Teams"
```

**private_mac/main.yml**:

```yaml
# Private Macs haben KEIN Munki
munki_update: false

# Wird nie ausgeführt, aber explizit:
munki_check_only: true
```

#### Ebene 3: Host Level (host_vars/ws547.yml)

Für spezifische Geräte wo Munki Updates tatsächlich installiert werden sollen:

**host_vars/ws547.yml** (Beispiel):

```yaml
# Dieses Gerät soll Munki Updates INSTALLIEREN
munki_check_only: false
munki_applesuspkgsonly: false
munki_munkipkgsonly: false
```

**host_vars/UMB-L3VWMGM77F.yml** (Beispiel - nur check):

```yaml
# Dieses Gerät soll nur checken (default behavior)
# munki_check_only: true  # Bereits durch group_vars gesetzt
```

---

## Implementation Plan

### Schritt 1: Update group_vars/macs/munki.yml

```yaml
---
# Munki Configuration - Global Defaults

# Check-only mode (safe default)
# Set to false in host_vars for devices that should auto-install updates
munki_check_only: true

# Default: Munki is disabled (overridden by business_mac group)
munki_update: false

# Optional: Skip updates if certain packages are in the update list
munki_skip_if_present: []
# Example:
# munki_skip_if_present:
#   - "Microsoft Teams"
#   - "Microsoft Word"

# Munki update filters (default: install all)
munki_applesuspkgsonly: false
munki_munkipkgsonly: false
```

### Schritt 2: Update business_mac/main.yml

```yaml
---
# Business Mac Configuration

# Enable Munki on business devices
munki_update: true

# Default to check-only mode (safe)
# Override in host_vars for specific devices that should install
munki_check_only: true

# Business-specific skip list
munki_skip_if_present:
  - "Microsoft Teams"  # Beispiel: Teams Updates manuell installieren
```

### Schritt 3: Update private_mac/main.yml

```yaml
---
# Private Mac Configuration

# Munki is not available on private devices
munki_update: false

# Not used but explicit
munki_check_only: true
```

### Schritt 4: Host-spezifische Konfiguration

Erstelle für jedes Gerät das Munki Updates installieren soll:

**host_vars/ws547.yml**:

```yaml
---
# ws547 - Business Laptop mit Auto-Update

# Override: This device should INSTALL Munki updates
munki_check_only: false

# Optional: Device-specific settings
# munki_skip_if_present:
#   - "Adobe Photoshop"  # Spezifisch für dieses Gerät
```

### Schritt 5: Update plays/update.yml (optional Verbesserung)

```yaml
roles:
  # ... andere roles

  - role: munki_update
    when:
      - munki_update | default(false) | bool
      - myenv == 'business_mac'  # Zusätzliche Sicherheit
    tags: ['munki']
```

---

## Testing

### Test 1: Check auf Business Mac (ws547)

```bash
# Run auf ws547 - sollte Munki checken (oder installieren wenn host_vars gesetzt)
ansible-playbook plays/update.yml -i inventories -l ws547 --connection=local --tags munki -v
```

**Erwartetes Ergebnis**:

- Munki role wird ausgeführt
- Check wird durchgeführt
- Installation nur wenn `munki_check_only: false` in host_vars

### Test 2: Skip auf Private Mac (odin)

```bash
# Run auf odin - sollte Munki überspringen
ansible-playbook plays/update.yml -i inventories -l odin --connection=local --tags munki -v
```

**Erwartetes Ergebnis**:

- Munki role wird ÜBERSPRUNGEN (when condition false)
- Output: "skipping: [odin]"

### Test 3: Dry-Run Check

```bash
# Check what would happen ohne Installation
ansible-playbook plays/update.yml -i inventories -l ws547 --connection=local --tags munki --check -v
```

---

## Configuration Matrix

| Host | Group | munki_update | munki_check_only | Verhalten |
|------|-------|--------------|------------------|-----------|
| ws547 | business_mac | true | true (default) | Check only |
| ws547 | business_mac | true | false (host_vars) | Install updates |
| UMB-L3VWMGM77F | business_mac | true | true (default) | Check only |
| odin | private_mac | false | n/a | Skip (role not run) |
| thor | private_mac | false | n/a | Skip (role not run) |

---

## Beispiel: Gerät für Auto-Install konfigurieren

Wenn du möchtest dass `ws547` automatisch Munki Updates installiert:

1. **Erstelle/Editiere** `inventories/host_vars/ws547.yml`:

   ```yaml
   ---
   # ws547 - Business Laptop mit Munki Auto-Update

   # Enable Munki update installation
   munki_check_only: false

   # Optional: Skip specific packages
   munki_skip_if_present:
     - "Microsoft Teams"
   ```

2. **Run update**:

   ```bash
   ansible-playbook plays/update.yml -i inventories -l ws547 --connection=local
   ```

3. **Verify**:
   - Check `/usr/local/munki/managedsoftwareupdate` logs
   - Output zeigt "Installing updates" statt nur "Checking"

---

## Ad-hoc Override via Extra Vars

Für einmaliges Install (ohne host_vars zu ändern):

```bash
# Force install auf einem specific host (override check_only)
ansible-playbook plays/update.yml -i inventories -l ws547 --connection=local \
  --tags munki \
  -e "munki_check_only=false"

# Force skip Munki auch auf business mac
ansible-playbook plays/update.yml -i inventories -l ws547 --connection=local \
  -e "munki_update=false"
```

---

## Empfohlene Defaults für neue Geräte

### Neues Business MacBook

1. **Add to** `inventories/macs.list`:

   ```ini
   [business_mac]
   ws547
   UMB-L3VWMGM77F
   ws999  # <-- Neues Gerät
   ```

2. **Create** `inventories/host_vars/ws999.yml`:

   ```yaml
   ---
   # ws999 - Business Laptop

   # Hostname (falls abweichend)
   # newhostname: ws999

   # Munki behavior (default is check-only from group)
   # Uncomment to enable auto-install:
   # munki_check_only: false
   ```

3. **Inherited from business_mac group**:
   - `munki_update: true`
   - `munki_check_only: true` (safe default)

### Neues Private MacBook

1. **Add to** `inventories/macs.list`:

   ```ini
   [private_mac]
   odin
   thor
   loki  # <-- Neues Gerät
   ```

2. **Create** `inventories/host_vars/loki.yml`:

   ```yaml
   ---
   # loki - Private MacBook

   # Munki not available on private devices
   # (inherited: munki_update: false)
   ```

---

## Monitoring & Logging

### Munki Check Output

Wenn `munki_check_only: true`:

```
TASK [munki_update : Check if updates are pending (via regex)] ****
ok: [ws547] => {
    "munki_updates_pending": true
}

TASK [munki_update : Show debug info (optional)] ****
ok: [ws547] => {
    "msg": "Updates pending: True, Skipped due to package match: False"
}

TASK [munki_update : Install pending updates with Munki] ****
skipping: [ws547] => (item=None)  # Skipped wegen check_only
```

Wenn `munki_check_only: false`:

```
TASK [munki_update : Install pending updates with Munki] ****
changed: [ws547] => {
    "changed": true,
    "cmd": ["/usr/local/munki/managedsoftwareupdate", "--installonly"],
    "rc": 0,
    "stdout": "Installing updates..."
}
```

---

## Zusammenfassung

### Was ist jetzt besser

1. ✅ **Klare 3-Level Hierarchie**:
   - Global (macs/) → Group (business_mac/) → Host (host_vars/)

2. ✅ **Safe Defaults**:
   - Munki OFF für private Macs
   - Munki Check-Only für business Macs
   - Opt-in für Auto-Install via host_vars

3. ✅ **Flexibilität**:
   - Pro-Device Kontrolle über check vs install
   - Ad-hoc Overrides via `-e` möglich
   - Skip-Pakete konfigurierbar

4. ✅ **Sicherheit**:
   - Kein ungewolltes Auto-Install
   - Private Macs niemals Munki
   - Explizite Opt-ins erforderlich

### Nächste Schritte

1. Implementiere die 4 Schritte oben
2. Teste auf einem Business Mac
3. Entscheide welche Geräte Auto-Install bekommen sollen
4. Erstelle host_vars für diese Geräte
