# Überblick über Aliases und Funktionen

Dieses Dokument fasst alle Shell-Aliases und Funktionsdefinitionen aus den dotfiles zusammen, die in folgenden Dateien gepflegt werden:
`.aliases`, `.functions` und `.bash_prompt`. Die Beschreibungen sind kurz gehalten und benennen die wichtigsten Effekte der jeweiligen Helfer.

## Aliases

### `.aliases`
- `ghorg`: Ruft `ghorg` über `op run` auf, damit GitHub-Organisationen mit dem 1Password-CLI-Wrapper geladen werden.
- `kdelerr`: Löscht fehlgeschlagene Kubernetes-Pods in allen Namespaces (`kubectl get ... | kubectl delete ...`).
- `doc`: Startet das Container-Image `tdeutsch/openshift-cli` interaktiv als Ersatz für das `oc`-CLI.
- `..`, `...`, `....`, `.....`: Kürzel für `cd ..`, `cd ../..`, `cd ../../..` bzw. `cd ../../../..`.
- `~`: Springt direkt ins Home-Verzeichnis (`cd ~`).
- `-`: Geht in das zuletzt besuchte Verzeichnis (`cd -`).
- `d`, `n`, `dl`, `dt`, `p`: Springen in häufig genutzte Ordner (`~/Documents/Dropbox`, `~/Documents/Nextcloud`, `~/Downloads`, `~/Desktop`, `~/projects`).
- `g`: Alias für `git`.
- `l`, `ll`: Listen Dateien im langen Format mit aktivierten Farben (`ls -lF ${colorflag}`).
- `la`: Langformat inklusive versteckter Dateien außer `.` und `..` (`ls -lAF ${colorflag}`).
- `lsd`: Listet nur Verzeichnisse (`ls -lF ... | grep '^d'`).
- `ls`: Erzwingt das farbige System-`ls` (`command ls ${colorflag}`).
- `grep`, `fgrep`, `egrep`: Aktivieren farbige Ausgabe für die jeweiligen Befehle.
- `sudo`: Erlaubt, dass nachfolgende Aliases mit `sudo` funktionieren (`sudo ` mit trailing space).
- `week`: Zeigt die Kalenderwoche (`date +%V`).
- `update`: Führt ein Komplettpaket an macOS-, Homebrew-, npm- und Ruby-Updates samt Aufräumarbeiten aus.
- `chrome`, `canary`: Starten Google Chrome bzw. Canary über den vollen App-Pfad.
- `ip`: Liest die öffentliche IP-Adresse via OpenDNS.
- `localip`: Ermittelt die lokale IP am Interface `en0`.
- `ips`: Zeigt alle IPv4- und IPv6-Adressen aus `ifconfig`.
- `ifactive`: Filtert aktive Netzwerk-Interfaces via `ifconfig` und `pcregrep`.
- `flush`: Leert den macOS-Verzeichnisdienst-Cache und startet mDNSResponder neu.
- `lscleanup`: Bereinigt LaunchServices-Einträge und startet den Finder neu.
- `hd`: Setzt `hd` auf `hexdump -C`, falls kein System-`hd` vorhanden ist.
- `md5sum`: Fällt auf `md5` (macOS) zurück, falls keine GNU-Version existiert.
- `sha1sum`: Fällt auf `shasum` zurück, falls keine GNU-Version existiert.
- `jsc`: Startet das JavaScriptCore-REPL, sofern die System-Binary vorhanden ist.
- `c`: Entfernt Zeilenumbrüche aus der Standardeingabe und kopiert ins Clipboard.
- `cleanup`: Löscht rekursiv alle `.DS_Store`-Dateien unterhalb des aktuellen Pfads.
- `emptydns`: Löscht den DNS-Cache (mDNSResponder) mit kurzer Wartepause.
- `emptytrash`: Leert den Papierkorb auf allen Volumes, löscht alte ASL-Logs und Quarantine-Einträge.
- `show`, `hide`: Schalten versteckte Dateien im Finder sichtbar/unsichtbar und starten den Finder neu.
- `hidedesktop`, `showdesktop`: Blenden Desktop-Icons aus oder wieder ein (inklusive Finder-Neustart).
- `urlencode`: Kodiert einen String URL-sicher über ein kurzes Python-Snippet.
- `mergepdf`: Kombiniert mehrere PDF-Dateien via Ghostscript zu `_merged.pdf`.
- `spotoff`, `spoton`: Deaktivieren bzw. aktivieren die Spotlight-Indizierung.
- `plistbuddy`: Kürzel für `/usr/libexec/PlistBuddy`.
- `airport`: Kürzel für die macOS-Airport-CLI.
- `map`: Führt `xargs -n1` aus, nützlich als „map“-Funktion in Pipes.
- `GET`, `HEAD`, `POST`, `PUT`, `DELETE`, `TRACE`, `OPTIONS`: Setzen `lwp-request -m <METHODE>` für schnelle HTTP-Anfragen.
- `stfu`, `pumpitup`: Stummschalten bzw. Maximallautstärke via AppleScript.
- `chromekill`: Beendet alle Chrome-Renderer-Prozesse außer Erweiterungsprozesse.
- `afk`: Versetzt den Mac in den Display-Schlafmodus (`pmset displaysleepnow`).
- `reload`: Lädt die aktuelle Shell als Login-Shell neu.
- `path`: Gibt jeden `PATH`-Eintrag in einer eigenen Zeile aus.

### `.functions`
- `open`: Wird auf Nicht-macOS-Systemen gesetzt und delegiert zu `explorer.exe` (WSL) oder `xdg-open` (Linux), um den `open`-Befehl plattformübergreifend verfügbar zu machen.

## Funktionen

### `.functions`
- `mergepr`: Sucht GitHub-Pull-Requests mit `feat`, `fix` oder `chore` im Titel und führt ein sequentielles `gh pr merge -d -m` durch.
- `randomstr [LÄNGE]`: Erzeugt einen zufälligen druckbaren String (Standard: 20 Zeichen) über `/dev/urandom`.
- `haste`: Liest STDIN, legt den Inhalt auf `https://paste.eighty-three.me` ab und gibt die Pasten-URL zurück.
- `hurryup BENUTZER HOST`: Versucht in einer Schleife per SSH zu verbinden, bis der Zugriff gelingt; nützlich, wenn ein Host erst hochfahren muss.
- `mkd PFAD`: Erstellt ein Verzeichnis (inklusive Eltern) und wechselt direkt hinein.
- `cdf`: Springt in den Ordner des obersten Finder-Fensters (macOS AppleScript).
- `targz PFAD...`: Erstellt ein `.tar`-Archiv und komprimiert es anschließend mit `zopfli`, `pigz` oder `gzip` (je nach Verfügbarkeit und Dateigröße).
- `fs [PFAD...]`: Zeigt Dateigrößen (`du`) – mit Byte-genauer Ausgabe, wenn GNU `du` verfügbar ist, ansonsten standardmäßig.
- `diff`: Wird nur definiert, wenn `git` vorhanden ist; nutzt `git diff --no-index --color-words` als allgemeines `diff`.
- `dataurl DATEI`: Baut eine `data:`-URL aus der Datei, inklusive MIME-Typ und Base64-Inhalt.
- `server [PORT]`: Startet einen einfachen Python-HTTP-Server (Default 8000), öffnet den Browser und erzwingt UTF-8/Text-Defaults.
- `phpserver [PORT]`: Startet `php -S` auf der lokalen IP von `en1` (Default 4000) und öffnet den Browser.
- `gz DATEI`: Vergleicht Original- und Gzip-Größe und berechnet das prozentuale Verhältnis.
- `digga DOMAIN`: Fragt nacheinander die DNS-Typen `A`, `AAAA`, `MX` und `CNAME` mit `dig` ab und zeigt die Antworten kompakt (`+multiline +noall +answer`).
- `getcertnames DOMAIN`: Holt das TLS-Zertifikat und zeigt `CN` sowie `SAN`-Einträge.
- `o [ZIEL]`: Öffnet das aktuelle Verzeichnis oder einen angegebenen Pfad mit dem `open`-Alias (plattformabhängig).
- `tre [PFAD]`: Führt `tree` mit versteckten Dateien und Farb-Hervorhebung aus und piped in `less`.
- `podman ...`: Wrapper, der bei Verbindungsfehlern die Podman Machine startet, auf den Socket wartet und den ursprünglichen Befehl erneut aufruft.
- `docker ...`: Wrapper für Docker unter Lima: startet bei Bedarf automatisch die Lima-Instanz, wartet auf den Socket und wiederholt den Aufruf.

### `.bash_prompt`
- `prompt_git PREFIX SUFFIX`: Ermittelt den aktuellen Git-Branch/Commit sowie Statusmarken (`+`, `!`, `?`, `$`) und baut die farbige Prompt-Komponente für `PS1`.
