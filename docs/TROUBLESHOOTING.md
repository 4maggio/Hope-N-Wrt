# Troubleshooting & FAQ

## Häufig gestellte Fragen

### F: Wie wechsle ich zwischen Hotspot- und AP-Modus?
**A:** Drei Möglichkeiten:
1. **WPS-Button**: Position 01 + 2x Klicks
2. **SSH**:
   ```bash
   uci set router_mode.config.router_mode='hotspot'  # oder 'ap'
   uci commit router_mode
   reboot
   ```
3. **Web-Interface**: (falls konfiguriert)

### F: Mein Router hat keine Internet-Verbindung
**A:** Prüfe in dieser Reihenfolge:
```bash
# 1. Modus prüfen
uci get router_mode.config.router_mode

# 2. Interfaces prüfen
ip address show

# 3. Gateway prüfen
ip route show

# 4. WAN-Status
ubus call network.interface.wan status

# 5. Logs schauen
logread | tail -30
```

### F: WLAN-Clients werden nicht erkannt
**A:** 
```bash
# WLAN Status
uci show wireless

# WiFi neu laden
wifi reload

# Client-Zähler manuell testen
iw dev phy0-ap0 station dump
iw dev phy0-ap1 station dump
```

### F: LED-Indikatoren funktionieren nicht
**A:**
```bash
# LED-System prüfen
ls -la /sys/class/leds/

# Test: WAN LED an
echo none > /sys/class/leds/green:wan/trigger
echo 1 > /sys/class/leds/green:wan/brightness

# Test: Blinken
echo timer > /sys/class/leds/green:wan/trigger
echo 100 > /sys/class/leds/green:wan/delay_on
echo 100 > /sys/class/leds/green:wan/delay_off
```

### F: WPS-Button funktioniert nicht
**A:**
```bash
# GPIO-Status prüfen
cat /sys/kernel/debug/gpio | head -20

# WPS-Button testen
cat /sys/class/gpio/gpio38/value

# rc.button Handler testen
sh /etc/rc.button/wps
```

### F: mwan3 Load-Balancing funktioniert nicht
**A:**
```bash
# Status checken
/etc/init.d/mwan3 status
mwan3ctl status

# Neukonfiguration
/usr/bin/configure_mwan3.sh loadbalancing

# Logs
logread -e mwan3

# Restart
/etc/init.d/mwan3 restart
```

## Fehlerdiagnose

### Router bootet nicht
**Symptome**: Schwarzer Bildschirm, keine LED-Aktivität
```bash
# Recovery-Mode aktivieren (Tasten halten beim Boot)
# Dann via Webbrowser flashen
```

### SSH-Zugang verloren
```bash
# Von anderem Gerät im Netzwerk:
nmap 192.168.1.0/24  # Router-IP finden

# Oder Recovery-Mode, dann reset:
factory reset
```

### Speicher voll
```bash
# Speicherplatz prüfen
df -h

# Große Dateien finden
find / -type f -size +10M 2>/dev/null

# Logs leeren
echo "" > /var/log/syslog

# Temporäre Dateien
rm -rf /tmp/*
```

## Performance-Optimierung

### Router wird heiß / CPU-Last hoch
```bash
# Laufende Prozesse checken
top

# router_monitor CPU-Optimierung (bereits implementiert):
# - Client-Zählung nur alle 10 Sekunden
# - Timeout bei iw-Befehlen
# - Caching von Ergebnissen

# Alternative: Monitoring deaktivieren (wenn nicht nötig)
/etc/init.d/router_monitor stop
/etc/init.d/router_monitor disable
```

### WiFi-Ausfälle oder Disconnects
```bash
# Kanal/Interferenzen prüfen
iw dev wlan0 survey dump

# TX-Power reduzieren (wenn zu hoch)
uci set wireless.radio0.txpower='17'  # statt 20
uci commit wireless
wifi reload

# 802.11d deaktivieren
uci set wireless.radio0.country='00'
uci commit wireless
```

## Log-Dateien verstehen

### Router Monitor Logs
```bash
logread -e "router_monitor" | tail -20

# Beispiel-Output:
# router_monitor: Schalterposition: 00 -> 01
# router_monitor: GPIO 38 nicht verfügbar
# router_monitor: WPS: Stoppe ksmbd
```

### mwan3 Logs
```bash
logread -e "mwan3"

# Beispiel:
# mwan3_config: Setting up load balancing
# mwan3: WAN interface is up
# mwan3: WWAN interface is down
```

### WiFi Logs
```bash
logread -e "wifi"
logread -e "hostapd"
logread -e "wpa_supplicant"
```

## Netzwerk-Debugging

### Routing-Tabelle prüfen
```bash
ip route show
ip rule show
```

### Firewall-Status
```bash
ufw status  # Falls installiert
iptables -L -n -v  # Direkt
```

### DNS-Resolution testen
```bash
nslookup google.com
dig @1.1.1.1 google.com
```

### Paket-Capture für Debugging
```bash
tcpdump -i eth0 -w capture.pcap
tcpdump -i wlan0 host 192.168.1.100
```

## Hardware-Tests

### GPIO-Test
```bash
# Alle GPIO auflisten
cat /sys/kernel/debug/gpio

# Spezifisches GPIO (z.B. 38 für WPS)
cat /sys/class/gpio/gpio38/value
```

### Speicher-Test
```bash
free -h
cat /proc/meminfo
```

### Systemtemperatur
```bash
# Falls thermal sensor
cat /sys/class/thermal/thermal_zone0/temp
```

## Sicherungs- und Wiederherstellungsverfahren

### Komplettes System sichern
```bash
# Archiv erstellen
tar czf router_backup_$(date +%Y%m%d_%H%M%S).tar.gz /etc/ /root/ /mnt/usb/

# Übertragen
scp root@192.168.1.1:/root/router_backup_*.tar.gz .
```

### Nur Konfiguration sichern
```bash
# UCI-Konfiguration
uci export > uci_backup.txt

# Wireless/Network
cp /etc/config/wireless wireless_backup
cp /etc/config/network network_backup
```

### Wiederherstellen
```bash
# UCI-Import
uci import < uci_backup.txt

# Oder manuell
uci merge < uci_backup.txt
```

## Kontakt und Support

Bei weiteren Problemen:
1. Logs prüfen: `logread | grep -i error`
2. Repository-Issues checken
3. OpenWRT-Forum konsultieren

## Performance-Metriken

Typische Werte für korrekten Betrieb:

| Metrik | Normal | Problem |
|--------|--------|---------|
| CPU-Last | < 50% | > 80% |
| Speicher | < 70% | > 90% |
| Temperatur | < 50°C | > 70°C |
| Ping LAN | < 5ms | > 20ms |
| WiFi-Durchsatz | > 20 Mbps | < 5 Mbps |
