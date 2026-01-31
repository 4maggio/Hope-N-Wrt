# Contributing

Vielen Dank für dein Interesse an diesem Projekt! Wir freuen uns über Beiträge.

## Repository Struktur

- `scripts/` — Die Haupt-Scripts (router_monitor, wifi_blink, etc.)
- `init.d/` — OpenWRT Init-Services
- `configs/` — Konfiguration Templates
- `docs/` — Dokumentation

## Branching Model

- `main` — Stable, releasable state
- `dev` — Integration branch für day-to-day work (wenn vorhanden)
- `feature/xxx` — Feature branches branchen von `main` oder `dev` ab

### Workflow

1. Erstelle einen Feature/Fix Branch: `git checkout -b feature/router-bugfix`
2. Mache fokussierte Commits mit klaren Nachrichten
3. Öffne einen Pull Request
4. Warte auf Review

## Pull Requests

Bitte beachte folgende Punkte in deinem PR:

- **Was hat sich geändert und warum?** — Klare Beschreibung
- **Welches Script betroffen?** — `router_monitor`, `wifi_blink`, etc.
- **Wie testen?** — Schritte oder Test-Befehle
- **Logs oder Output?** — Bei Bugs: relevant error output
- **Breaking Changes?** — Wenn ja, deutlich kennzeichnen

## Quality Bar

- Keep changes **minimal and scoped** — Eine Sache pro PR
- **Backward compatible** wo möglich — Keine Breaking Changes ohne Grund
- **Getestet** — Code vor PR testen
- **Dokumentiert** — Changes in README/CONFIGURATION.md falls nötig
- **POSIX-konform** — Shell-Scripts sollten auf OpenWRT laufen

## Code Style

### Shell-Scripts
```bash
#!/bin/sh
# Kurze Beschreibung

# Globale Variablen (UPPERCASE)
MY_VAR="value"

# Funktionen (snake_case)
my_function() {
    local local_var="$1"
    logger -t my_script "Nachricht: $local_var"
    return 0
}

# Fehlerbehandlung
set -e  # Exit bei Fehler
set -u  # Exit wenn Variable nicht gesetzt
```

### Kommentare
- Deutsch (wie bestehender Code)
- Klar und verständlich
- Erkläre das WARUM, nicht das WAS

### Commit Messages
Format: `[Bereich] Kurze Beschreibung`

```
[scripts] Fix router_monitor LED-Blinken beim Startup
[docs] Update CONFIGURATION.md mit mwan3 Beispiel
[configs] Add new wireless template for dual-band
[fix] Correct GPIO export timing in router_monitor
```

## Testing

### Lokales Testen (Linux/Mac)
```bash
# Shell-Syntax prüfen
sh -n script.sh
shellcheck script.sh  # Falls installiert

# Auf dem Router testen
ssh root@192.168.1.1
cd /mnt/usb/router-project
sh install.sh

# Logs prüfen
logread | tail -50
logread -e router_monitor
```

### Was vor PR testen
- [ ] Script startet ohne Fehler
- [ ] LEDs blinken korrekt (falls LED-relevant)
- [ ] Logs show keine Errors
- [ ] Installation funktioniert (`sh install.sh`)
- [ ] Update funktioniert (`sh deploy.sh`)

## Dokumentation

### README.md ändern?
- Halten wir aktuell und anfänger-freundlich
- Deutsche Sprache
- Neue Features? → Auch in docs/ dokumentieren

### docs/ Dateien
- **CONFIGURATION.md** — How-to für Setup
- **TROUBLESHOOTING.md** — FAQ und Debugging
- Neue Docs? — Ask first via Issue

## Community

Dieses Projekt folgt unserem `CODE_OF_CONDUCT.md`. Wir erwarten:

- **Respekt und Konstruktivität**
- **Positive Kommunikation**
- **Keine Diskriminierung oder Belästigung**
- **Hilfsbereitschaft** gegenüber anderen

## Lizenz

Mit deinem Beitrag akzeptierst du, dass dein Code unter der im LICENSE definierten Lizenz veröffentlicht wird.

## Fragen?

Öffne einen GitHub Issue oder Discussion. Wir helfen gerne! 🙏

---

**Danke dass du zum Projekt beiträgst! 🚀**
