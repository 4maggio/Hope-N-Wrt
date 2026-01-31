# GitHub Templates & Contributing Standards

Dieses Repository folgt jetzt professionellen GitHub-Standards ähnlich dem [adobe-crap](https://github.com/4maggio/adobe-crap) Projekt.

## 📋 Neue Dateien

### Root-Level
- **CONTRIBUTING.md** — Detaillierte Richtlinien für Beiträge
- **CODE_OF_CONDUCT.md** — Verhaltensrichtlinien der Community
- **PULL_REQUEST_TEMPLATE.md** — Template für Pull Requests
- **ISSUE_TEMPLATE.md** — Template für Issues

### `.github/` Ordner (GitHub-spezifisch)
```
.github/
├── ISSUE_TEMPLATE/
│   ├── bug_report.yml           # Strukturiertes Bug-Report Template
│   ├── feature_request.yml      # Feature-Request Template
│   └── config.yml               (optional für weitere Templates)
├── pull_request_template.md     # PR-Template
└── workflows/                   # GitHub Actions (zur Expansion)
```

## 🎯 Standards

### Branching Model
- `main` — Production-ready, stable
- `dev` — Integration branch (optional)
- `feature/xxx` — Feature branches
- `fix/xxx` — Bug-fix branches

### Commit Messages
Format: `[Bereich] Kurze Beschreibung`

```bash
[scripts] Fix router_monitor LED-Blinken beim Startup
[docs] Update CONFIGURATION.md mit mwan3 Beispiel
[configs] Add new wireless template for dual-band
```

### Pull Request Anforderungen
- ✅ Klare Beschreibung was geändert wurde
- ✅ Begründung warum Änderung notwendig ist
- ✅ Test-Schritte durchgeführt
- ✅ Logs/Output bei Bugs
- ✅ Dokumentation aktualisiert

### Quality Bar
1. **Minimal & Scoped** — Eine Sache pro PR
2. **Getestet** — Vor PR testen
3. **Dokumentiert** — README/Docs aktualisieren
4. **Backward-compatible** — Keine Breaking Changes ohne Grund
5. **POSIX-konform** — Shell-Scripts auf OpenWRT

## 🤝 Community Guidelines

Aus CODE_OF_CONDUCT.md:
- ✅ Respekt und Konstruktivität
- ✅ Positive Kommunikation
- ❌ Keine Diskriminierung
- ❌ Keine Belästigung
- ✅ Hilfsbereitschaft untereinander

## 📝 Wie wird verwendet

### Für Bug Reports
Benutzer wählen in GitHub: **New Issue** → **Bug Report** → Formulare wird angezeigt

### Für Feature Requests
Benutzer wählen in GitHub: **New Issue** → **Feature Request** → Formulare wird angezeigt

### Für Pull Requests
Bei PR erstellen wird automatisch Template angezeigt

## 🔗 Referenzen

Dieses Repository folgt den Best Practices von:
- [adobe-crap](https://github.com/4maggio/adobe-crap) — Repository-Struktur
- GitHub Community Standards
- Open Source Conventions

## ✨ Was kommt als nächstes?

Optional (nicht notwendig für MVP):
- [ ] GitHub Actions Workflow für Syntax-Check
- [ ] Release Automation
- [ ] Badge für README
- [ ] Wiki für erweiterte Doku
- [ ] Discussions statt Issues für Fragen

---

**Dein Repository ist jetzt bereit für die Open-Source Community! 🚀**
