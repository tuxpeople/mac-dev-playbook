# munki_update Ansible Role

Diese Rolle prüft und installiert Software-Updates über Munki (`managedsoftwareupdate`) auf macOS-Systemen.

## Variablen

- `munki_check_only`: Nur prüfen, nicht installieren (bool, default: `false`)
- `munki_skip_if_present`: Liste von Paketnamen, bei deren Auftauchen keine Installation durchgeführt wird (default: `[]`)
- `munki_applesuspkgsonly`: Nur Apple SUS Pakete verarbeiten (default: `false`)
- `munki_munkipkgsonly`: Nur Munki Pakete verarbeiten (default: `false`)
