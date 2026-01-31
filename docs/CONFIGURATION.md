# Konfigurationsleitfaden für TP-Link Mini Router

## Überblick

Dieses Projekt bietet eine komplette Lösung für einen flexiblen OpenWRT Router mit zwei Betriebsmodi. Dieser Guide behandelt alle notwendigen Konfigurationsschritte.

## 1. Basis-Setup

### 1.1 Hardware-Voraussetzungen
- TP-Link Mini Router (Archer MR200 oder ähnlich)
- USB-Speicher mit ext4 Dateisystem (mind. 512 MB)
- Ethernet-Kabel und Stromversorgung
- Computer mit SSH-Client (PuTTY, Terminal, etc.)

### 1.2 OpenWRT Installation
Falls noch nicht durchgeführt:
1. OpenWRT Image von [openwrt.org](https://openwrt.org) herunterladen
2. Via Web-Interface oder SSH flashen
3. Router mit SSH erreichbar (Standard: `ssh root@192.168.1.1`)

## 2. Erste Schritte nach Installation

### 2.1 USB-Stick mounten
```bash
ssh root@192.168.1.1

# USB-Stick prüfen
ls -la /dev/

# Manuell mounten (falls nicht automatisch)
mkdir -p /mnt/usb
mount /dev/sda1 /mnt/usb

# Automatisches Mounten (persistent)
uci add fstab mount
uci set fstab.@mount[-1].target='/mnt/usb'
uci set fstab.@mount[-1].device='/dev/sda1'
uci set fstab.@mount[-1].fstype='ext4'
uci set fstab.@mount[-1].options='defaults'
uci set fstab.@mount[-1].enabled='1'
uci commit fstab
/etc/init.d/fstab restart
```

### 2.2 Projekt installieren
```bash
cd /mnt/usb/router-project
sh install.sh
```

## 3. WLAN-Konfiguration (WICHTIG!)

### 3.1 Wireless-Config anpassen
```bash
# Editor öffnen
vi /etc/config/wireless

# ODER mit uci (einfacher)
uci set wireless.wifinet1.ssid='MeinNetworkName'
uci set wireless.wifinet1.key='MeinSuperSicheresPasswort'  # Mind. 8 Zeichen!
uci set wireless.wifinet2.ssid='MeinGastNetwork'
uci set wireless.wifinet2.key='GastPasswort'
uci set wireless.wifinet0.ssid='iPhone'  # Ziel-Netzwerk für Hotspot
uci set wireless.wifinet0.key='iPhonePasswort'

# Speichern
uci commit wireless

# Laden
wifi reload
```

**Wichtige SSID-Namen:**
- `wifinet0`: Hotspot-Verbindung (5G Client) - nur im Hotspot-Modus aktiv
- `wifinet1`: Hauptnetzwerk (2.4 GHz AP) - immer aktiv
- `wifinet2`: Gast-Netzwerk (2.4 GHz AP) - optional

### 3.2 Netzwerk-Interfaces konfigurieren
```bash
# LAN-IP einstellen (Standard 192.168.1.1)
uci set network.lan.ipaddr='192.168.1.1'
uci set network.lan.netmask='255.255.255.0'

# Gast-Netzwerk (separates Subnetz)
uci set network.guest.ipaddr='192.168.2.1'
uci set network.guest.netmask='255.255.255.0'

uci commit network
/etc/init.d/network reload
```

## 4. Router-Modus einstellen

### 4.1 Hotspot-Modus
```bash
# Router verbindet sich zu 5G-Netzwerk und verteilt Internet
uci set router_mode.config.router_mode='hotspot'
uci commit router_mode

# Dann Neustart
reboot
```

### 4.2 AP-Modus
```bash
# Router bekommt Internet via Ethernet
uci set router_mode.config.router_mode='ap'
uci set router_mode.config.ap_submode='lan-fallback'  # oder lan-only, loadbalancing
uci commit router_mode

reboot
```

**AP-Submodi:**
- `lan-only`: Nur Ethernet, kein 5G Fallback
- `lan-fallback`: Ethernet primär, 5G Fallback (mwan3)
- `loadbalancing`: Ethernet und 5G parallel

## 5. mwan3 Konfiguration (Multi-WAN)

Nur notwendig für AP-Modus mit `lan-fallback` oder `loadbalancing`:

### 5.1 Automatische Konfiguration (empfohlen)
```bash
# Wird automatisch gemacht wenn Modus gewechselt wird
# Oder manuell:

# LAN-Fallback
/usr/bin/configure_mwan3.sh lan-fallback

# Load-Balancing
/usr/bin/configure_mwan3.sh loadbalancing

# Deaktivieren
/usr/bin/configure_mwan3.sh disable
```

### 5.2 mwan3 Status prüfen
```bash
/etc/init.d/mwan3 status
mwan3ctl status
```

## 6. Firewall und Sicherheit

### 6.1 Firewall konfigurieren
```bash
# Gast-Netzwerk isolieren (Standard)
uci set firewall.guestzone=zone
uci set firewall.guestzone.name='guest'
uci set firewall.guestzone.input='REJECT'
uci set firewall.guestzone.output='ACCEPT'
uci set firewall.guestzone.forward='REJECT'
uci set firewall.guestzone.network='guest'

uci commit firewall
/etc/init.d/firewall reload
```

### 6.2 Root-Passwort ändern
```bash
passwd
# Neues Passwort eingeben
```

### 6.3 SSH-Schlüssel (empfohlen)
```bash
# Lokal:
ssh-keygen -t ed25519 -f ~/.ssh/router_key

# Auf Router:
mkdir -p /root/.ssh
cat ~/.ssh/router_key.pub | ssh root@192.168.1.1 'cat >> /root/.ssh/authorized_keys'

# SSH mit Passwort deaktivieren:
uci set dropbear.@dropbear[0].PasswordAuth='0'
uci commit dropbear
/etc/init.d/dropbear restart
```

## 7. DHCP und DNS

### 7.1 DHCP-Pools einstellen
```bash
# LAN
uci set dhcp.lan.start='100'
uci set dhcp.lan.limit='150'
uci set dhcp.lan.leasetime='12h'

# Gast-Netzwerk
uci set dhcp.guest=dhcp
uci set dhcp.guest.interface='guest'
uci set dhcp.guest.start='100'
uci set dhcp.guest.limit='100'
uci set dhcp.guest.leasetime='1h'

uci commit dhcp
/etc/init.d/dnsmasq restart
```

### 7.2 DNS-Server
```bash
# CloudFlare und Google DNS
uci set dhcp.@dnsmasq[0].server='1.1.1.1' '8.8.8.8'
uci commit dhcp
/etc/init.d/dnsmasq restart
```

## 8. Services und Monitoring

### 8.1 Wichtige Services starten
```bash
# Router Monitor (LEDs, Schalter, Shutdown)
/etc/init.d/router_monitor enable
/etc/init.d/router_monitor start

# WiFi Connect Blinker
/etc/init.d/wifi_connect_blink enable
/etc/init.d/wifi_connect_blink start

# mwan3 (falls Fallback/Load-Balancing)
/etc/init.d/mwan3 enable
/etc/init.d/mwan3 start

# Firewall
/etc/init.d/firewall enable

# Netzwerk
/etc/init.d/network enable
```

### 8.2 Status prüfen
```bash
# Laufende Prozesse
ps | grep -E "router_monitor|wifi_connect"

# Systemlogs
logread | tail -50

# Service-Status
/etc/init.d/router_monitor status
```

## 9. LED-Indikatoren verstehen

| LED | Modus | Bedeutung |
|-----|-------|-----------|
| **Power** | Hotspot | Aus |
| **Power** | AP | Internet verfügbar (an) oder nicht (blinkt) |
| **WAN** | Hotspot | 5G verbunden (an) oder nicht (blinkt) |
| **WAN** | AP | 5G verfügbar (langsam blinkt) oder nicht (schnell blinkt) |
| **WLAN** | - | Morse-Code: Anzahl LAN-Clients |
| **WPS** | - | Morse-Code: Anzahl Gast-Clients |
| **USB** | - | ksmbd (SMB-Freigabe) an (an) oder aus (aus) |

Morse-Code Beispiel: 3 Blinke (kurz-kurz-kurz) Pause = 3 verbundene Clients

## 10. WPS-Button Funktionen

Der WPS-Button ist ein 2x2 Schalter mit 4 verschiedenen Positionen. Die Position wird durch das Schalter-Layout bestimmt:

```
    [Schalter Ansicht von oben]
    
    Position 01     Position 10
    ┌────┐          ┌────┐
    │ ││ │          │ │  │
    │ └┘ │          │  ━ │
    └────┘          └────┘
    Router-Mode     WLAN-Einst.
    
    Position 00     Position 11
    ┌────┐          ┌────┐
    │    │          │ ││ │
    │  ━ │          │ └┘ │
    └────┘          └────┘
    (unused)        System
```

### Position 01 - Router-Einstellungen
**Für die Verwaltung des Router-Modus und AP-Submodi:**

- **1x Klick**: AP-Submode ändern (nur wenn router_mode='ap')
  - Wechselt zwischen: lan-only → lan-fallback → loadbalancing → lan-only
  
- **2x Klicks (langsam)**: Router-Mode umschalten
  - Wechselt zwischen: hotspot ↔ ap
  - Nach Wechsel: Automatischer Neustart des Routers
  - LED-Feedback: Alle LEDs blinken schnell während des Wechsels

### Position 10 - WLAN-Einstellungen
**Für die Verwaltung der Funknetzwerke:**

- **1x Klick**: Hauptnetzwerk (wifinet1 @ 2.4 GHz) an/aus
  - SSID: Ihr konfigurierter MAIN_SSID
  - Clients: Verbundene Geräte werden sofort getrennt
  - LED-Feedback: WLAN LED blinkt beim Umschalten
  
- **2x Klicks (langsam)**: Gast-WLAN (wifinet2 @ 2.4 GHz) an/aus
  - SSID: Ihr konfigurierter GUEST_SSID
  - Isolation: Gast-Clients können untereinander nicht kommunizieren
  - LED-Feedback: WPS LED blinkt beim Umschalten

### Position 11 - System-Einstellungen
**Für System-Verwaltung und Shutdown:**

- **1x Klick**: USB-Share (SMB/ksmbd & WebDAV) an/aus
  - Aktiviert/Deaktiviert Netzwerk-Dateifreigabe
  - Netzwerk-Pfad: `smb://192.168.1.1/usb` (Standard)
  - LED-Feedback: USB LED leuchtet (an) oder aus (aus)
  
- **2x Klicks (langsam)**: Sauberes Herunterfahren (graceful shutdown)
  - Services werden ordnungsgemäß beendet
  - Alle LEDs blinken schnell während des Shutdowns
  - Nach ~10 Sekunden: Router ausgeschaltet
  - Neustart: Stromversorgung aus und wieder an

### Praktische Beispiele

**Beispiel 1: AP-Modus mit Load-Balancing aktivieren**
1. Position 01 einstellen
2. 1x klicken → lan-only wird zu lan-fallback
3. 1x klicken → lan-fallback wird zu loadbalancing
4. ✓ Fertig

**Beispiel 2: Gast-WLAN deaktivieren**
1. Position 10 einstellen
2. 2x klicken (kurz hintereinander)
3. WPS LED blinkt → Gast-WLAN ist aus
4. ✓ Fertig

**Beispiel 3: Router sauberer neustarten**
1. Position 11 einstellen
2. 2x klicken (kurz hintereinander)
3. Alle LEDs blinken schnell
4. Router fährt herunter
5. Nach ~30 Sekunden: Von vorne starten (via Stromversorgung)

### Fehlerbehebung WPS-Button

Wenn Button nicht reagiert:
```bash
# WPS-Button Handler testen
sh /etc/rc.button/wps

# GPIO 38 Status prüfen (WPS-Button = GPIO 38)
cat /sys/class/gpio/gpio38/value
# 0 = gedrückt
# 1 = nicht gedrückt

# Logs prüfen
logread | grep -E "router_monitor|mode_switch|wps_button"
```

## 11. Backup und Updates

### 11.1 Konfiguration sichern
```bash
# Komplettes Backup erstellen
uci export > /mnt/usb/uci_backup_$(date +%Y%m%d_%H%M%S).tar
tar czf /mnt/usb/config_backup_$(date +%Y%m%d_%H%M%S).tar.gz /etc/config/

# Backup aufspielen
tar xzf /mnt/usb/config_backup_20240101_120000.tar.gz -C /
```

### 11.2 Script-Updates deployen
```bash
cd /mnt/usb/router-project
sh deploy.sh
```

## 12. Problembehebung

### LED-Status-Checker
```bash
# Alle LEDs ausgeben
ls -la /sys/class/leds/

# LED Test (grüne WAN LED)
echo "none" > /sys/class/leds/green\:wan/trigger
echo "1" > /sys/class/leds/green\:wan/brightness  # An
echo "0" > /sys/class/leds/green\:wan/brightness  # Aus
```

### GPIO-Debug
```bash
# Schalterposition prüfen
cat /sys/kernel/debug/gpio | grep "sw[12]"

# WPS-Button prüfen
cat /sys/class/gpio/gpio38/value
```

### Internet-Verbindung testen
```bash
# WAN-Status (AP-Modus)
ubus call network.interface.wan status

# WWAN-Status (Hotspot)
ubus call network.interface.wwan status

# Ping-Test
ping -c 3 1.1.1.1
```

## Häufige Fehler

| Problem | Lösung |
|---------|--------|
| WLAN nicht sichtbar | `wifi reload` oder `uci show wireless` prüfen |
| Internet offline | `ubus call network.interface.wan status` prüfen |
| mwan3 funktioniert nicht | `/etc/init.d/mwan3 restart` |
| Router Monitor stoppt | `logread \| grep router_monitor` zur Fehlersuche |
| Kein SSH-Zugang | Router via Recovery-Mode flashen |

## Kontakt & Lizenz

Dieses Projekt steht unter der AGPL3-Lizenz.
Weitere Informationen finden Sie in [LICENSE](../LICENSE).
