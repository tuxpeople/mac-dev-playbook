# ✅ macOS 26 – Manuelle Konfigurations-Checkliste

**Erstellt:** 2025-12-24
**macOS Version:** 26.2 (Sequoia 15.2)
**Quelle:** `docs/analysis/BROKEN_DOMAIN_SETTINGS.md`

> Diese Einstellungen müssen manuell konfiguriert werden, da die entsprechenden `defaults write` Befehle in macOS 26 nicht mehr funktionieren.

---

## 🧭 Safari – Datenschutz, Sicherheit & UX

### 🔐 Datenschutz & Suche

- ⬜ Safari → **Einstellungen → Suche**

  - ⬜ „Suchmaschinenvorschläge einschließen“ **deaktivieren**
  - ⬜ „Spotlight-Vorschläge einschließen“ **deaktivieren**

- ⬜ Safari → **Einstellungen → Datenschutz**

  - ⬜ „Betrügerische Websites warnen“ **aktivieren**

---

### 🔗 Navigation & Darstellung

- ⬜ Safari → **Einstellungen → Erweitert**

  - ⬜ „Tab-Taste hebt jedes Element auf einer Webseite hervor“ **aktivieren**

- ⬜ Safari → **Einstellungen → Allgemein**

  - ⬜ „Vollständige Website-Adresse anzeigen“ **aktivieren**
  - ⬜ Startseite auf `about:blank` setzen _(optional)_

---

### 📥 Downloads & Dateiverhalten

- ⬜ Safari → **Einstellungen → Allgemein**

  - ⬜ „Sichere Dateien nach dem Laden öffnen“ **deaktivieren**

---

### 🧑‍💻 Entwickler- & Debug-Funktionen

- ⬜ Safari → **Einstellungen → Erweitert**

  - ⬜ „Menü ‚Entwickler‘ in der Menüleiste anzeigen“ **aktivieren**

- ⬜ Safari → **Entwickler-Menü**

  - ⬜ Web-Inspector verfügbar prüfen

_(Hinweis: Interne Debug-Menüs sind nicht mehr aktivierbar)_

---

### 📝 Text & Rechtschreibung

- ⬜ Safari → **Einstellungen**

  - ⬜ Rechtschreibprüfung **aktiv**
  - ⬜ Autokorrektur **deaktivieren** (falls gewünscht)

---

### 🛡️ Sicherheit & Web-Verhalten

- ⬜ Safari → **Einstellungen → Sicherheit**

  - ⬜ Pop-up-Fenster **blockieren**

- ℹ️ Java / Plugins:

  - ❌ Nicht mehr relevant (Safari unterstützt kein Java mehr)

---

### 🕵️ Tracking

- ℹ️ „Do Not Track“:

  - ❌ Nicht mehr vorhanden / Web-Standard deprecated

---

### 🧩 Erweiterungen

- ⬜ Safari → **Einstellungen → Erweiterungen**

  - ⬜ Automatische Updates **aktiv** (Standard)

---

## ✉️ Mail.app – Bedienung & Verhalten

### 🎞️ Animationen

- ℹ️ Senden-/Antwort-Animationen:

  - ❌ Nicht mehr abschaltbar

---

### 📋 E-Mail-Adressen kopieren

- ℹ️ Nur Adresse statt `Name <mail@…>`:

  - ❌ Nicht mehr konfigurierbar

---

### ⌨️ Tastenkürzel (wichtig)

- ⬜ **Systemeinstellungen → Tastatur → Tastaturkurzbefehle**

  - ⬜ App-Kurzbefehl hinzufügen:

    - App: **Mail**
    - Menüpunkt: **Senden**
    - Tastenkürzel: **⌘ + Enter**

---

### 🧵 Konversationen & Sortierung

- ⬜ Mail → **Darstellung**

  - ⬜ „Nach Konversationen ordnen“ nach Wunsch

- ⬜ Mail → **Darstellung → Sortieren nach**

  - ⬜ Datum / Reihenfolge manuell einstellen

---

### 📎 Anhänge

- ℹ️ Inline-Anhänge deaktivieren:

  - ❌ Nicht mehr möglich (Standardverhalten)

---

### ✍️ Rechtschreibung

- ⬜ Mail → **Bearbeiten → Rechtschreibung und Grammatik**

  - ⬜ Automatische Rechtschreibprüfung **deaktivieren** (falls gewünscht)

---

## 🔐 Apple Watch Unlock (macOS)

- ⬜ **Systemeinstellungen → Touch ID & Passwort**

  - ⬜ „Apple Watch zum Entsperren verwenden“ **manuell aktivieren**

**Hinweise bei Problemen:**

- Watch & Mac neu starten
- iCloud kurz ab- und wieder anmelden
- WLAN + Bluetooth aktiv
- Kein Ethernet-only-Betrieb

---

## 🧠 Meta-Hinweise (wichtig)

- ❗ Diese Einstellungen sind **bewusst nicht mehr per CLI automatisierbar**
- ❗ Änderungen können durch iCloud-Sync überschrieben werden
- ✅ Diese Checkliste ist **der stabilste Weg** unter macOS ≥ 26

---

## 📚 Siehe auch

- **Automatisierte Settings:** `inventories/group_vars/macs/defaults.yml` (90 Settings via Ansible)
- **Verbleibende CLI-Settings:** `~/dotfiles/.macos` (38 defaults write)
- **Broken Settings Analyse:** `docs/analysis/BROKEN_DOMAIN_SETTINGS.md`
- **Migration Dokumentation:** `docs/sessions/FINAL_MIGRATION_STATS_2025-12-24.md`

---

## 📊 Fortschritt

- [ ] Safari (13 Punkte)
- [ ] Mail (6 Punkte)
- [ ] Apple Watch (1 Punkt)

**Zuletzt aktualisiert:** _____
