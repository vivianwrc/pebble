# Pebble – Webseite

Dieses Repository ist die öffentliche Webseite von Pebble (GitHub Pages, Branch `main`, Ordner `/`).
Live: https://vivianwrc.github.io/pebble/

## Woher das Spiel kommt
Die Quelle ist das Claude-Artifact „Pebble“: https://claude.ai/artifact/8HQVqanDsStDH6YT7uzCmE
`index.html` wird daraus erzeugt, nie direkt von Hand bearbeiten.

## Aktualisieren
1. Artifact lesen (Artifact-Tool, action "read", die URL oben) und das vollständige HTML als `Pebble.html` speichern (nicht committen).
2. `python3 tools/build.py Pebble.html index.html` ausführen. Das Skript ergänzt Manifest, Icons, Supabase und schreibt `version.txt`.
3. Nur wenn sich `index.html` geändert hat: committen und auf `main` pushen. Die Seite ist 1–2 Minuten später aktuell.

## Online-Spielstände
`config.js` verbindet mit Supabase (Projekt der Pingpaar-App, Frankfurt). Tabelle `pebble_saves`, siehe `supabase.sql`.
Der publishable-Schlüssel ist öffentlich und darf im Repo stehen. Niemals einen secret/service_role-Schlüssel eintragen.
