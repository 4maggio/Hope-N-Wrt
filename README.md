# TP-Link Mini Router - OpenWRT Multi-Mode Projekt

Ein eigenständiger, flexibler Router basierend auf OpenWRT für TP-Link Mini Router mit zwei Betriebsmodi:
- **Hotspot-Modus**: Internet über 5G (z.B. iPhone Hotspot)
- **AP-Modus**: Internet über Ethernet-Kabel mit Fallback/Load-Balancing

## Features

### Router Modi
- **Hotspot-Modus**: Der Router verbindet sich selbst zu einem 5G-Netzwerk und verteilt dieses
- **AP-Modus** mit 3 Submodi:
  - **LAN-Only**: Nur Ethernet, 5G deaktiviert
  - **LAN-Fallback**: Ethernet primär, 5G als Notfallverbindung
  - **Load-Balancing**: Ethernet und 5G parallel (mwan3)

### LED-Indikatoren
- **Power LED**: Internet-Status (Mode-abhängig)
- **WAN LED**: Internet-Fallback oder Hotspot-Status
- **WLAN LED**: Hauptnetzwerk (Morse-Code: Anzahl verbundener Clients)
- **WPS LED**: Gast-Netzwerk (Morse-Code: Anzahl verbundener Clients)
- **USB LED**: ksmbd (SMB/Dateifreigabe) Status

### WPS-Button
Kontrolliert Router-Funktion über 2x2 Schalter-Positionen:
- **Position 01**: Mode-Einstellungen (1x=Submode, 2x=Router-Mode)
- **Position 10**: WLAN-Einstellungen (1x=Hauptnetzwerk, 2x=Gast-WLAN)
- **Position 11**: System (1x=USB-Share, 2x=Shutdown)

## Hardware

- TP-Link Mini Router (z.B. Archer MR200)
- USB-Speicher für Installation
- Ethernet-Kabel und Stromversorgung

## Installation

### Voraussetzungen
- OpenWRT 21.02+ oder neuer
- SSH-Zugriff zum Router
- USB-Speicher mit genug Platz

### Schnell-Installation

1. **USB-Stick vorbereiten** (ext4 Dateisystem):
   ```bash
   # Linux/Mac
   mkfs.ext4 /dev/sdX1
   ```

2. **Projekt-Dateien kopieren**:
   ```bash
   mount /dev/sdX1 /mnt/usb
   cp -r router-project /mnt/usb/
   unmount /mnt/usb
   ```

3. **USB an Router anschließen und mounten**:
   ```bash
   # SSH zum Router
   ssh root@192.168.1.1
   
   # USB manuell mounten (wenn nicht automatisch)
   mkdir -p /mnt/usb
   mount /dev/sda1 /mnt/usb
   ```

4. **Installation starten**:
   ```bash
   cd /mnt/usb/router-project
   sh install.sh
   ```
   
   **WICHTIG**: Nach `install.sh` zeigt das Script eine Warnung:
   ```
   ⚠ ACHTUNG: Template-Dateien müssen manuell kopiert werden:
      cp configs/wireless.template /etc/config/wireless
      cp configs/network.template /etc/config/network
      Dann Platzhalter ersetzen!
   ```

5. **Konfiguration anpassen**:
   ```bash
   # Wireless-Template kopieren und bearbeiten
   cp /mnt/usb/router-project/configs/wireless.template /etc/config/wireless
   
   # Editor öffnen und Platzhalter ersetzen:
   # - MAIN_SSID → Ihr WLAN-Name
   # - MAIN_PASSWORD → Ihr Passwort
   # - GUEST_SSID → Gast-Netzwerk-Name
   # - GUEST_PASSWORD → Gast-Passwort
   vi /etc/config/wireless
   
   # Netzwerk-Template (optional, Standard-IPs sind OK)
   cp /mnt/usb/router-project/configs/network.template /etc/config/network
   
   # Änderungen committen
   uci commit wireless
   uci commit network
   wifi reload
   ```

6. **Router Neustart**:
   ```bash
   reboot
   ```

## Konfiguration

### Wichtige Einstellungsschritte

1. **WLAN-Namen und Passwörter ändern** (→ `/etc/config/wireless`)
   - `MAIN_SSID` + `MAIN_PASSWORD`: Hauptnetzwerk
   - `GUEST_SSID` + `GUEST_PASSWORD`: Gast-WLAN
   - `WWAN_SSID` + `WWAN_PASSWORD`: Ziel-Hotspot (für Hotspot-Modus)

2. **Router-Modus setzen** (→ `/etc/config/router_mode`)
   ```bash
   uci set router_mode.config.router_mode='ap'
   uci set router_mode.config.ap_submode='lan-fallback'
   uci commit router_mode
   ```

3. **Services aktivieren**:
   ```bash
   /etc/init.d/router_monitor enable
   /etc/init.d/wifi_connect_blink enable
   /etc/init.d/router_monitor start
   /etc/init.d/wifi_connect_blink start
   ```

### Verwaltung per WPS-Button

Der WPS-Button ermöglicht schnelle Umschaltungen ohne SSH:

- **Position 01 + 1x Klick**: AP-Submode ändern (nur im AP-Modus)
- **Position 01 + 2x Klicks**: Router-Mode umschalten (Hotspot ↔ AP)
- **Position 10 + 1x Klick**: Hauptnetzwerk an/aus
- **Position 10 + 2x Klicks**: Gast-WLAN an/aus
- **Position 11 + 1x Klick**: USB-Freigabe (lighttpd) an/aus
- **Position 11 + 2x Klicks**: Router sauber herunterfahren

## Skripte

### `router_monitor.sh` (Haupt-Monitor)
- Überwacht GPIO-Schalter und WPS-Button
- Steuert LED-Status basierend auf Modus und Internet-Verbindung
- Kümmert sich um sauberes Herunterfahren
- Zeigt Morse-Code LED-Blinken für verbundene WLAN-Clients

**Logfile**: `logread | grep router_monitor`

### `wifi_connect_blink.sh` (WLAN-Blinker)
- Blinkt LEDs wenn neue Clients sich verbinden
- Optische Rückmeldung für erfolgreiche Verbindungen

### `switch_router_mode.sh`
- Umschalter zwischen Hotspot und AP-Modus
- Konfiguriert Interfaces und Firewall automatisch

### `configure_mwan3.sh`
- Konfiguriert Multi-WAN (mwan3) für Fallback/Load-Balancing
- Modi: `lan-fallback`, `loadbalancing`, `disable`

## Troubleshooting

### Router bootet nicht
- LED-Blinken beobachten (normal = langsames grünes Blinken)
- SSH: `ssh root@192.168.1.1` (Standard-Passwort: admin)

### WLAN nicht sichtbar
```bash
ssh root@192.168.1.1
uci show wireless
# Sicherstellen dass wifinet1.disabled='0' und wifinet2.disabled='0'
wifi reload
```

### Internet-Verbindung nicht erkannt
```bash
# Status prüfen
ubus call network.interface.wan status
ubus call network.interface.wwan status

# Logs schauen
logread | tail -20
```

### mwan3 Probleme
```bash
# Status
/etc/init.d/mwan3 status
mwan3ctl status

# Restart
/etc/init.d/mwan3 restart
```

## Logs und Debugging

Wichtige Log-Quellen:
```bash
# System-Logs (alle Services)
logread | tail -50

# Nur Router Monitor
logread -e router_monitor

# Nur WiFi Connect
logread -e wifi_blink

# Netzwerk-Debug
logread -e network

# UCI Konfiguration prüfen
uci show                    # Alle Configs
uci show wireless          # Nur Wireless
uci show network           # Nur Network
```

## Updates deployen

Nach Änderungen am Code:
```bash
cd /mnt/usb/router-project
sh deploy.sh
```

Dies kopiert alle aktuellen Dateien auf den Router und startet Services neu.

## Sicherheit

### Passwort ändern
```bash
# Root-Passwort setzen
passwd
```

### SSH-Keys (empfohlen)
```bash
# Lokal
ssh-keygen -t ed25519 -f ~/.ssh/router_id

# Auf Router
mkdir -p /root/.ssh
cat ~/.ssh/router_id.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# /etc/config/dropbear
uci set dropbear.@dropbear[0].PasswordAuth='0'
uci commit dropbear
```

## Lizenz

AGPL3 License - Frei zu verwenden, zu modifizieren und zu verteilen.

**Wichtig**: Wenn Sie Änderungen vornehmen und verteilen, müssen Sie den Quellcode auch veröffentlichen.
Siehe [LICENSE](LICENSE) für die vollständige Lizenz.

## Support

Bei Fragen oder Problemen:
1. Logs prüfen: `logread | grep -E "router_monitor|wifi_blink|mode_switch|mwan3"`
2. Konfiguration validieren: `uci show`
3. Services neu starten: `/etc/init.d/router_monitor restart`
