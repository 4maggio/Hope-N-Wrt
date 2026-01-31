## Beschreibung

Bitte beschreibe die Änderungen und erkläre warum sie notwendig sind.

Fixes #(issue number)

## Typ der Änderung

Bitte relevante Optionen wählen:

- [ ] 🐛 Bug Fix (non-breaking change der ein Problem behebt)
- [ ] ✨ Feature (non-breaking change der neue Funktionalität hinzufügt)
- [ ] 📚 Dokumentation (Änderung an Dokumentation)
- [ ] ⚙️ Configuration (Änderung an Config-Templates)
- [ ] 🔧 Refactoring (Code-Verbesserung ohne Funktionsänderung)
- [ ] 🚀 Performance (Verbesserung der Performance)

## Betroffene Scripts/Dateien

- [ ] `router_monitor.sh`
- [ ] `wifi_connect_blink.sh`
- [ ] `wps_button.sh`
- [ ] `switch_router_mode.sh`
- [ ] `configure_mwan3.sh`
- [ ] Config-Templates
- [ ] Dokumentation
- [ ] Sonstiges: _______

## Wie getestet?

Bitte beschreibe wie du diese Änderungen getestet hast:

```bash
# Test-Schritte
ssh root@192.168.1.1
cd /mnt/usb/router-project
sh install.sh
# ... weitere Test-Schritte
```

## Test Checklist

- [ ] Script startet ohne Fehler
- [ ] Logs zeigen keine Errors (`logread | tail`)
- [ ] Neue Features funktionieren wie erwartet
- [ ] Installation funktioniert (`sh install.sh`)
- [ ] Bestehende Funktionalität nicht beschädigt

## Screenshots/Output (falls relevant)

Falls UI-Changes oder wichtiger Output, bitte einfügen.

## Breaking Changes?

- [ ] Nein, dies ist eine non-breaking change
- [ ] Ja, und ich habe eine Migration beschrieben

## Dokumentation

- [ ] Ich habe die README.md aktualisiert
- [ ] Ich habe CONFIGURATION.md aktualisiert  
- [ ] Ich habe TROUBLESHOOTING.md aktualisiert
- [ ] Nicht relevant für diese PR

## Weitere Informationen

Zusätzliche Kontexte oder Informationen die hilfreich sind.
