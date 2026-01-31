# Sicherheitsrichtlinien

Dieses Projekt ist für den öffentlichen Gebrauch bestimmt. Folgende Richtlinien sollten beachtet werden:

## Sensitive Daten NICHT im Repository

❌ **Nicht committen:**
- WLAN-Passwörter
- SSH-Private-Keys
- Root-Passwörter
- IP-Adressen (spezifisch)
- MAC-Adressen
- Backup-Dateien
- Persönliche Konfigurationen

✅ **Stattdessen verwenden:**
- Template-Dateien (`.template`)
- Dokumentation mit Platzhaltern
- `.gitignore` für lokale Konfiguration
- Environment-Variablen
- Secrets-Management

## Lokale Konfiguration

Nach dem Clonen musst du folgende Dateien lokal anpassen:

```bash
# Templates kopieren und bearbeiten
cp configs/wireless.template /etc/config/wireless
cp configs/network.template /etc/config/network
cp configs/router_mode.template /etc/config/router_mode

# Dann mit echten Werten füllen
vi /etc/config/wireless
# Ersetze: MAIN_SSID, MAIN_PASSWORD, GUEST_SSID, WWAN_SSID, etc.
```

## Git Best Practices

### Vor dem Push prüfen
```bash
# Sensitive Dateien suchen
git diff --cached | grep -E "password|secret|key|credential"

# Größe überprüfen (sollte < 1MB sein)
du -sh .git

# Nur Templates committen
git add *.template
git add docs/
git add scripts/
git add init.d/
git add install.sh deploy.sh
```

### .gitignore beachten
```bash
# Alle Dateien auflisten die ignoriert werden
git check-ignore -v .

# Prüfen was committed würde
git diff --cached --name-only
```

## SSH-Sicherheit

### Passwort-Auth deaktivieren
```bash
uci set dropbear.@dropbear[0].PasswordAuth='0'
uci commit dropbear
/etc/init.d/dropbear restart
```

### SSH-Keys verwenden
```bash
# Client-Seite
ssh-keygen -t ed25519 -f ~/.ssh/router_key -N ""

# Server-Seite
mkdir -p ~/.ssh
cat ~/.ssh/router_key.pub | ssh root@192.168.1.1 'cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'

# Test
ssh -i ~/.ssh/router_key root@192.168.1.1
```

## Firewall-Sicherheit

### UFW (falls installiert)
```bash
ufw enable
ufw allow 22/tcp  # SSH
ufw allow 80/tcp  # HTTP
ufw allow 443/tcp # HTTPS
```

### Iptables direkt
```bash
# SSH nur von LAN
iptables -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP
```

## Gast-Netzwerk Isolation

Das Projekt isoliert Gast-WLAN automatisch:

```bash
# Isolations-Prüfung
uci get firewall.guestzone.forward
# Sollte 'REJECT' sein
```

## Regelmäßige Updates

```bash
# OpenWRT Updates prüfen
opkg update
opkg list-upgradable

# Dieses Projekt aktualisieren
git pull
sh deploy.sh
```

## Sichere Passwort-Verwaltung

### Sichere Passwörter generieren
```bash
# Linux/Mac
openssl rand -base64 12

# Online-Generator verwenden (z.B. bitwarden.com/password-generator)
```

### Passwort-Anforderungen
- Mindestens 12 Zeichen
- Großbuchstaben, Kleinbuchstaben, Zahlen, Sonderzeichen
- Keine Wörterbuch-Worte
- Eindeutig pro Netzwerk

## Audit und Logging

### Sicherheits-Audit
```bash
# Failed SSH logins
cat /var/log/auth.log | grep "Failed password"

# Firewall-Events
iptables -L -v

# Open Ports
netstat -tlnp
```

### Verdächtige Aktivitäten
```bash
# Aktuelle Verbindungen
netstat -an

# Prozesse mit Netzwerk-Zugriff
lsof -i

# SSH-Brute-Force prüfen
logread | grep "sshd.*Failed" | wc -l
```

## Kontributoren-Richtlinien

Wenn du zum Projekt beiträgst:

1. **Keine Credentials committen** - Nutze .gitignore
2. **Code-Review** vor Merge
3. **Security-Check** - Sensitive Strings nach Hardcoding suchen
4. **Dokumentation** - Sicherheits-Implikationen erklären
5. **Tests** - Sicherheits-Features testen

## Sicherheits-Disclosure

Falls Sicherheitslücke gefunden:

1. **Nicht öffentlich posten**
2. Mail an: [owner-email] mit Details
3. Warte auf Response
4. Arbeite an Fix
5. Veröffentliche nach Patch

## Zusätzliche Ressourcen

- [OpenWRT Security](https://openwrt.org/docs/guide-user/security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [SSH Best Practices](https://ssh.com/ssh/public-key-authentication)

---

**Letzte Aktualisierung**: Januari 2026
**Sicherheits-Level**: Informativ (nicht produktive Systeme)
