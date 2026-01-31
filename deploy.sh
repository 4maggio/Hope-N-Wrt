#!/bin/sh
#
# Deploy Script für OpenWRT Router
# Kopiert aktualisierte Dateien und startet Services neu
#
# USAGE: sh deploy.sh
#

set -e  # Exit bei Fehler

REPO_DIR="${0%/*}"
if [ ! -f "$REPO_DIR/scripts/router_monitor.sh" ]; then
    echo "ERROR: router-project Verzeichnis nicht gefunden!"
    echo "Bitte stelle sicher, dass deploy.sh im router-project Verzeichnis liegt"
    exit 1
fi

cd "$REPO_DIR"

echo "========================================="
echo "Router Project Deployment"
echo "========================================="
echo ""

# 1. Scripte aktualisieren
echo "[1/4] Aktualisiere Scripte..."
cp -v scripts/router_monitor.sh /usr/bin/ 2>/dev/null || true
cp -v scripts/wifi_connect_blink.sh /usr/bin/ 2>/dev/null || true
cp -v scripts/switch_router_mode.sh /usr/bin/ 2>/dev/null || true
cp -v scripts/configure_mwan3.sh /usr/bin/ 2>/dev/null || true
cp -v scripts/wps_button.sh /etc/rc.button/wps 2>/dev/null || true

chmod +x /usr/bin/router_monitor.sh 2>/dev/null || true
chmod +x /usr/bin/wifi_connect_blink.sh 2>/dev/null || true
chmod +x /usr/bin/switch_router_mode.sh 2>/dev/null || true
chmod +x /usr/bin/configure_mwan3.sh 2>/dev/null || true
chmod +x /etc/rc.button/wps 2>/dev/null || true

echo "✓ Scripte aktualisiert"
echo ""

# 2. Init-Scripte aktualisieren
echo "[2/4] Aktualisiere Init-Scripte..."
cp -v init.d/router_monitor /etc/init.d/ 2>/dev/null || true
cp -v init.d/wifi_connect_blink /etc/init.d/ 2>/dev/null || true

chmod +x /etc/init.d/router_monitor 2>/dev/null || true
chmod +x /etc/init.d/wifi_connect_blink 2>/dev/null || true

echo "✓ Init-Scripte aktualisiert"
echo ""

# 3. Konfiguration aktualisieren (nur wenn unterschiedlich)
echo "[3/4] Prüfe Konfiguration..."
if [ -f /etc/config/router_mode ]; then
    echo "⚠ router_mode existiert, überspringe Update"
else
    cp -v configs/router_mode.template /etc/config/router_mode 2>/dev/null || true
    echo "✓ Neue Konfiguration erstellt"
fi

echo "⚠ ACHTUNG: Template-Dateien manuell prüfen:"
echo "   diff /etc/config/wireless configs/wireless.template"
echo "   diff /etc/config/network configs/network.template"
echo ""

# 4. Services neu starten
echo "[4/4] Starte Services neu..."
echo "Stoppe Router Monitor..."
/etc/init.d/router_monitor stop 2>/dev/null || true
sleep 1

echo "Stoppe WiFi Connect Blinker..."
/etc/init.d/wifi_connect_blink stop 2>/dev/null || true
sleep 1

echo "Starte Router Monitor..."
/etc/init.d/router_monitor start 2>/dev/null || true
sleep 1

echo "Starte WiFi Connect Blinker..."
/etc/init.d/wifi_connect_blink start 2>/dev/null || true

echo "✓ Services neu gestartet"
echo ""

echo "========================================="
echo "Deployment erfolgreich abgeschlossen!"
echo "========================================="
echo ""
echo "Status prüfen:"
echo "  ps | grep router_monitor"
echo "  ps | grep wifi_connect"
echo "  logread | tail"
