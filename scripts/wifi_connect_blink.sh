#!/bin/sh
# WiFi Client Connect Blinker - Version für beide APs

PIDFILE="/var/run/wifi_connect_blink.pid"
LED_WLAN="/sys/class/leds/green:wlan"
LED_WPS="/sys/class/leds/green:wps"
BLINK_DELAY=100
MIN_BLINK_SEC=1

# PID-Lock
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if [ -d "/proc/$OLD_PID" ]; then
        exit 0
    fi
fi
echo $$ > "$PIDFILE"
trap "rm -f $PIDFILE /tmp/wifi_client_connecting_wlan /tmp/wifi_client_connecting_wps" EXIT

logger -t wifi_blink "WiFi Connect Blinker gestartet"

# Interfaces
WLAN_IFACE="phy0-ap0"
GUEST_IFACE="phy0-ap1"

# Client-Zähler Funktion
get_client_count() {
    local iface="$1"
    iw dev "$iface" station dump 2>/dev/null | grep -c "^Station"
}

# Initial Count
LAST_WLAN_COUNT=$(get_client_count "$WLAN_IFACE")
LAST_GUEST_COUNT=$(get_client_count "$GUEST_IFACE")

logger -t wifi_blink "Start: WLAN=$LAST_WLAN_COUNT, Gast=$LAST_GUEST_COUNT Clients"

while true; do
    # Check WLAN (phy0-ap0)
    WLAN_DISABLED=$(uci get wireless.wifinet1.disabled 2>/dev/null)
    if [ "$WLAN_DISABLED" != "1" ]; then
        CURRENT_WLAN=$(get_client_count "$WLAN_IFACE")
        
        if [ "$CURRENT_WLAN" -gt "$LAST_WLAN_COUNT" ]; then
            logger -t wifi_blink "WLAN: Neuer Client ($LAST_WLAN_COUNT -> $CURRENT_WLAN)"
            
            # Flag setzen
            echo "1" > /tmp/wifi_client_connecting_wlan
            
            # Schnelles Blinken
            echo "timer" > "$LED_WLAN/trigger"
            echo $BLINK_DELAY > "$LED_WLAN/delay_on"
            echo $BLINK_DELAY > "$LED_WLAN/delay_off"
            
            # Warte Mindestzeit im Background
            (
                sleep $MIN_BLINK_SEC
                rm -f /tmp/wifi_client_connecting_wlan
                logger -t wifi_blink "WLAN: Blink beendet"
            ) &
        fi
        LAST_WLAN_COUNT=$CURRENT_WLAN
    fi
    
    # Check Gast (phy0-ap1)
    GUEST_DISABLED=$(uci get wireless.wifinet2.disabled 2>/dev/null)
    if [ "$GUEST_DISABLED" != "1" ]; then
        CURRENT_GUEST=$(get_client_count "$GUEST_IFACE")
        
        if [ "$CURRENT_GUEST" -gt "$LAST_GUEST_COUNT" ]; then
            logger -t wifi_blink "Gast: Neuer Client ($LAST_GUEST_COUNT -> $CURRENT_GUEST)"
            
            # Flag setzen
            echo "1" > /tmp/wifi_client_connecting_wps
            
            # Schnelles Blinken
            echo "timer" > "$LED_WPS/trigger"
            echo $BLINK_DELAY > "$LED_WPS/delay_on"
            echo $BLINK_DELAY > "$LED_WPS/delay_off"
            
            # Warte Mindestzeit im Background
            (
                sleep $MIN_BLINK_SEC
                rm -f /tmp/wifi_client_connecting_wps
                logger -t wifi_blink "Gast: Blink beendet"
            ) &
        fi
        LAST_GUEST_COUNT=$CURRENT_GUEST
    fi
    
    sleep 1
done
