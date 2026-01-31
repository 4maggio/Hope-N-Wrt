name: Pull Request
description: Schreib etwas Großartiges

on:
  pull_request:
    branches: [main, dev]
    types: [opened, synchronize, reopened, ready_for_review]

body:
  - type: markdown
    attributes:
      value: |
        # Pull Request
        
        Danke für deinen Beitrag! Bitte fülle diese Informationen aus.

  - type: textarea
    id: description
    attributes:
      label: Beschreibung
      description: Beschreibe die Änderungen und warum sie notwendig sind
      placeholder: Diese PR...
    validations:
      required: true

  - type: input
    id: fixes
    attributes:
      label: Fixes Issue
      description: "Fixes #(issue number)"
      placeholder: "Fixes #123"
    validations:
      required: false

  - type: dropdown
    id: type
    attributes:
      label: Typ der Änderung
      options:
        - "🐛 Bug Fix"
        - "✨ Feature"
        - "📚 Dokumentation"
        - "⚙️ Configuration"
        - "🔧 Refactoring"
        - "🚀 Performance"
    validations:
      required: true

  - type: checkboxes
    id: files
    attributes:
      label: Betroffene Scripts/Dateien
      options:
        - label: "`router_monitor.sh`"
        - label: "`wifi_connect_blink.sh`"
        - label: "`wps_button.sh`"
        - label: "`switch_router_mode.sh`"
        - label: "`configure_mwan3.sh`"
        - label: "Config-Templates"
        - label: "Dokumentation"

  - type: textarea
    id: testing
    attributes:
      label: Test-Schritte
      description: Wie wurde die Änderung getestet?
      placeholder: |
        ```bash
        ssh root@192.168.1.1
        cd /mnt/usb/router-project
        sh install.sh
        ```
    validations:
      required: true

  - type: checkboxes
    id: tests
    attributes:
      label: Test Checklist
      options:
        - label: "Script startet ohne Fehler"
          required: true
        - label: "Logs zeigen keine Errors"
          required: true
        - label: "Neue Features funktionieren"
          required: false
        - label: "Installation funktioniert (`sh install.sh`)"
          required: false
        - label: "Bestehende Funktionalität nicht beschädigt"
          required: true

  - type: checkboxes
    id: breaking
    attributes:
      label: Breaking Changes
      options:
        - label: "Nein, non-breaking change"
        - label: "Ja, mit Migration beschrieben"

  - type: checkboxes
    id: documentation
    attributes:
      label: Dokumentation
      options:
        - label: "README.md aktualisiert"
        - label: "CONFIGURATION.md aktualisiert"
        - label: "TROUBLESHOOTING.md aktualisiert"
        - label: "Nicht relevant"
