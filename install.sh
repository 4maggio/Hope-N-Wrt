#!/bin/sh
#
# Install Script für OpenWRT Router
# Erstinstallation mit Service-Aktivierung
#
# USAGE: sh install.sh
#

set -e  # Exit bei Fehler

REPO_DIR="${0%/*}"
if [ ! -f "$REPO_DIR/scripts/router_monitor.sh" ]; then
    echo "ERROR: router-project Verzeichnis nicht gefunden!"
    echo "Bitte stelle sicher, dass install.sh im router-project Verzeichnis liegt"
    exit 1
fi

cd "$REPO_DIR"

echo "========================================="
echo "Router Project Installation"
echo "========================================="
echo ""

# 1. Scripte kopieren
echo "[1/5] Installiere Scripte..."
cp -v scripts/router_monitor.sh /usr/bin/ 2>/dev/null || true
cp -v scripts/wifi_connect_blink.sh /usr/bin/ 2>/dev/null || true
cp -v scripts/switch_router_mode.sh /usr/bin/ 2>/dev/null || true
cp -v scripts/configure_mwan3.sh /usr/bin/ 2>/dev/null || true
cp -v scripts/wps_button.sh /etc/rc.button/wps 2>/dev/null || true

# Permissions setzen
chmod +x /usr/bin/router_monitor.sh 2>/dev/null || true
chmod +x /usr/bin/wifi_connect_blink.sh 2>/dev/null || true
chmod +x /usr/bin/switch_router_mode.sh 2>/dev/null || true
chmod +x /usr/bin/configure_mwan3.sh 2>/dev/null || true
chmod +x /etc/rc.button/wps 2>/dev/null || true

echo "✓ Scripte installiert"
echo ""

# 2. Init-Scripte kopieren
echo "[2/5] Installiere Init-Scripte..."
cp -v init.d/router_monitor /etc/init.d/ 2>/dev/null || true
cp -v init.d/wifi_connect_blink /etc/init.d/ 2>/dev/null || true

# Permissions setzen
chmod +x /etc/init.d/router_monitor 2>/dev/null || true
chmod +x /etc/init.d/wifi_connect_blink 2>/dev/null || true

echo "✓ Init-Scripte installiert"
echo ""

# 3. Config kopieren (nur wenn nicht vorhanden)
echo "[3/5] Installiere Konfiguration..."
if [ ! -f /etc/config/router_mode ]; then
    cp -v configs/router_mode.template /etc/config/router_mode 2>/dev/null || true
    echo "✓ Neue Konfiguration erstellt: /etc/config/router_mode"
else
    echo "⚠ Konfiguration existiert bereits, überspringe..."
fi

echo "⚠ ACHTUNG: Template-Dateien müssen manuell kopiert werden:"
echo "   cp configs/wireless.template /etc/config/wireless"
echo "   cp configs/network.template /etc/config/network"
echo "   Dann Platzhalter ersetzen!"
echo ""

# 4. Services aktivieren
echo "[4/5] Aktiviere Services..."
/etc/init.d/router_monitor enable 2>/dev/null || true
/etc/init.d/wifi_connect_blink enable 2>/dev/null || true

echo "✓ Services aktiviert"
echo ""

# 5. Services starten
echo "[5/5] Starte Services..."
/etc/init.d/router_monitor start 2>/dev/null || true
/etc/init.d/wifi_connect_blink start 2>/dev/null || true

echo "✓ Services gestartet"
echo ""

echo "========================================="
echo "Installation erfolgreich abgeschlossen!"
echo "========================================="
echo ""
echo "WICHTIG - Nächste Schritte:"
echo "1. WiFi-Namen und Passwörter ändern:"
echo "   uci edit wireless"
echo ""
echo "2. Router-Modus konfigurieren:"
echo "   uci show router_mode"
echo ""
echo "3. Status prüfen:"
echo "   ps | grep router_monitor"
echo "   ps | grep wifi_connect"
echo "   logread | tail -20"
echo ""
echo "Für Updates nutze: sh deploy.sh"
