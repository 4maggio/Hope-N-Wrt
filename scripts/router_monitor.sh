#!/bin/sh
# Router Monitor - Multi-Mode Support (Hotspot/AP mit Sub-Modi)

PIDFILE="/var/run/router_monitor.pid"

if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if [ -d "/proc/$OLD_PID" ]; then
        logger -t router_monitor "Bereits laufende Instanz (PID $OLD_PID) gefunden. Beende."
        exit 0
    else
        logger -t router_monitor "Alte PID-Datei gefunden, Prozess existiert nicht mehr. Starte neu."
        rm -f "$PIDFILE"
    fi
fi

echo $$ > "$PIDFILE"
trap "rm -f $PIDFILE" EXIT

LAST_SWITCH_STATE=""
WPS_GPIO="/sys/class/gpio/gpio38"
LAST_WPS_STATE="1"
WLAN_CLIENT_CHECK_COUNTER=0
WLAN_CLIENTS_CACHED=0
WPS_CLIENT_CHECK_COUNTER=0
WPS_CLIENTS_CACHED=0
MORSE_COUNTER_WLAN=0
MORSE_COUNTER_WPS=0

# Exportiere WPS GPIO falls nötig (nur wenn GPIO 38 vorhanden ist)
if [ ! -d "$WPS_GPIO" ]; then
    if grep -q "gpio38" /sys/kernel/debug/gpio 2>/dev/null; then
        echo 38 > /sys/class/gpio/export 2>/dev/null
        sleep 1
        echo in > $WPS_GPIO/direction 2>/dev/null
    else
        logger -t router_monitor "GPIO 38 nicht verfügbar auf dieser Hardware, skipping WPS GPIO"
    fi
fi

all_leds_blink() {
    echo timer > /sys/class/leds/green:wps/trigger
    echo 100 > /sys/class/leds/green:wps/delay_on
    echo 100 > /sys/class/leds/green:wps/delay_off

    echo timer > /sys/class/leds/green:wlan/trigger
    echo 100 > /sys/class/leds/green:wlan/delay_on
    echo 100 > /sys/class/leds/green:wlan/delay_off

    echo timer > /sys/class/leds/green:wan/trigger
    echo 100 > /sys/class/leds/green:wan/delay_on
    echo 100 > /sys/class/leds/green:wan/delay_off

    echo timer > /sys/class/leds/green:usb/trigger
    echo 100 > /sys/class/leds/green:usb/delay_on
    echo 100 > /sys/class/leds/green:usb/delay_off

    echo timer > /sys/class/leds/green:power/trigger
    echo 100 > /sys/class/leds/green:power/delay_on
    echo 100 > /sys/class/leds/green:power/delay_off
}

safe_shutdown() {
    logger -t router_monitor "SHUTDOWN: WPS+Schalter erkannt"
    all_leds_blink
    sleep 2
    logger -t router_monitor "SHUTDOWN: Committe nlbwmon..."
    killall -USR1 nlbwmon 2>/dev/null
    sleep 1
    logger -t router_monitor "SHUTDOWN: Sync filesystems..."
    sync
    logger -t router_monitor "SHUTDOWN: Poweroff..."
    poweroff
}

# Morse-Code Funktion
morse_blink_led() {
    local led_path="$1"
    local counter="$2"
    local clients="$3"
    
    if [ "$clients" -eq 0 ]; then
        echo none > "$led_path/trigger"
        echo 1 > "$led_path/brightness"
    else
        echo none > "$led_path/trigger"
        
        # Berechne aktuelle Blink-Phase
        local blink_phase=$((counter % (clients * 2 + 2)))
        
        if [ "$blink_phase" -lt $((clients * 2)) ]; then
            # Innerhalb der Blink-Sequenz
            if [ $((blink_phase % 2)) -eq 0 ]; then
                echo 1 > "$led_path/brightness"
            else
                echo 0 > "$led_path/brightness"
            fi
        else
            # Pause zwischen Sequenzen
            echo 0 > "$led_path/brightness"
        fi
    fi
}

# Internet-Status prüfen
check_internet() {
    # Prüfe wwan (Hotspot)
    local wwan_up=0
    if ubus call network.interface.wwan status 2>/dev/null | grep -q '"up": true'; then
        wwan_up=1
    fi
    
    # Prüfe LAN (eth0) - TODO: echte Interface-Prüfung
    local lan_up=0
    if ip link show eth0 2>/dev/null | grep -q "state UP"; then
        # Zusätzlich Gateway-Check
        if ip route | grep -q "default.*eth0"; then
            lan_up=1
        fi
    fi
    
    echo "$wwan_up:$lan_up"
}

# LED-Steuerung basierend auf Modus
update_internet_leds() {
    local router_mode=$(uci get router_mode.config.router_mode 2>/dev/null || echo "hotspot")
    local ap_submode=$(uci get router_mode.config.ap_submode 2>/dev/null || echo "lan-only")
    local inet_status=$(check_internet)
    local wwan_up=$(echo $inet_status | cut -d: -f1)
    local lan_up=$(echo $inet_status | cut -d: -f2)
    
    # Power LED und WAN LED Logik
    case "$router_mode" in
        "hotspot")
            # Hotspot: WAN LED = Internet, Power LED = aus
            echo none > /sys/class/leds/green:power/trigger
            echo 0 > /sys/class/leds/green:power/brightness

            if [ "$wwan_up" = "1" ]; then
                # Internet via Hotspot verbunden
                echo none > /sys/class/leds/green:wan/trigger
                echo 1 > /sys/class/leds/green:wan/brightness
            else
                # Keine Internet-Verbindung - schnell blinken
                echo timer > /sys/class/leds/green:wan/trigger
                echo 100 > /sys/class/leds/green:wan/delay_on
                echo 100 > /sys/class/leds/green:wan/delay_off
            fi
            ;;

        "ap")
            case "$ap_submode" in
                "lan-only")
                    # LAN only: Power LED = Internet, WAN LED = AUS (5G deaktiviert)
                    echo none > /sys/class/leds/green:wan/trigger
                    echo 0 > /sys/class/leds/green:wan/brightness

                    if [ "$lan_up" = "1" ]; then
                        echo none > /sys/class/leds/green:power/trigger
                        echo 1 > /sys/class/leds/green:power/brightness
                    else
                        # Keine LAN-Verbindung - schnell blinken
                        echo timer > /sys/class/leds/green:power/trigger
                        echo 100 > /sys/class/leds/green:power/delay_on
                        echo 100 > /sys/class/leds/green:power/delay_off
                    fi
                    ;;

                "lan-fallback")
                    # Fallback: Power LED = Internet, WAN LED = langsam blinken (1s)
                    if [ "$wwan_up" = "1" ]; then
                        # 5G hat Internet - langsam blinken
                        echo timer > /sys/class/leds/green:wan/trigger
                        echo 1000 > /sys/class/leds/green:wan/delay_on
                        echo 1000 > /sys/class/leds/green:wan/delay_off
                    else
                        # 5G keine Verbindung - schnell blinken
                        echo timer > /sys/class/leds/green:wan/trigger
                        echo 100 > /sys/class/leds/green:wan/delay_on
                        echo 100 > /sys/class/leds/green:wan/delay_off
                    fi

                    if [ "$lan_up" = "1" ] || [ "$wwan_up" = "1" ]; then
                        echo none > /sys/class/leds/green:power/trigger
                        echo 1 > /sys/class/leds/green:power/brightness
                    else
                        # Keine Verbindung - schnell blinken
                        echo timer > /sys/class/leds/green:power/trigger
                        echo 100 > /sys/class/leds/green:power/delay_on
                        echo 100 > /sys/class/leds/green:power/delay_off
                    fi
                    ;;

                "loadbalancing")
                    # Load Balancing: WAN LED = dauerhaft an (wenn 5G verbunden)
                    if [ "$wwan_up" = "1" ]; then
                        # 5G hat Internet - dauerhaft an
                        echo none > /sys/class/leds/green:wan/trigger
                        echo 1 > /sys/class/leds/green:wan/brightness
                    else
                        # 5G keine Verbindung - schnell blinken
                        echo timer > /sys/class/leds/green:wan/trigger
                        echo 100 > /sys/class/leds/green:wan/delay_on
                        echo 100 > /sys/class/leds/green:wan/delay_off
                    fi
                    
                    if [ "$lan_up" = "1" ] || [ "$wwan_up" = "1" ]; then
                        echo none > /sys/class/leds/green:power/trigger
                        echo 1 > /sys/class/leds/green:power/brightness
                    else
                        # Keine Verbindung - schnell blinken
                        echo timer > /sys/class/leds/green:power/trigger
                        echo 100 > /sys/class/leds/green:power/delay_on
                        echo 100 > /sys/class/leds/green:power/delay_off
                    fi
                    ;;
            esac
            ;;
    esac
}

logger -t router_monitor "Router Monitor gestartet (PID $$) - Multi-Mode Support"

WPS_CHECK_COUNTER=0

while true; do
    # === 1. Schalterposition prüfen (jeden Loop) ===
    GPIO_STATE=$(cat /sys/kernel/debug/gpio 2>/dev/null)

    if echo "$GPIO_STATE" | grep "sw1" | grep -q " lo "; then
        SW1=0
    else
        SW1=1
    fi

    if echo "$GPIO_STATE" | grep "sw2" | grep -q " lo "; then
        SW2=0
    else
        SW2=1
    fi

    CURRENT_SWITCH="${SW1}${SW2}"

    if [ "$CURRENT_SWITCH" != "$LAST_SWITCH_STATE" ] && [ -n "$LAST_SWITCH_STATE" ]; then
        logger -t router_monitor "Schalterposition: $LAST_SWITCH_STATE -> $CURRENT_SWITCH"
    fi
    LAST_SWITCH_STATE="$CURRENT_SWITCH"

    # === WPS-Button: ksmbd Toggle (nur alle 2 Sekunden prüfen) ===
    WPS_CHECK_COUNTER=$(($WPS_CHECK_COUNTER + 1))
    if [ "$WPS_CHECK_COUNTER" -ge 2 ] && [ -f "/sys/class/gpio/gpio38/value" ] && [ "$SW1" = "1" ]; then
        WPS_CHECK_COUNTER=0
        WPS_STATE=$(cat /sys/class/gpio/gpio38/value 2>/dev/null)
        if [ "$WPS_STATE" = "0" ] && [ "$LAST_WPS_STATE" = "1" ]; then
            if ps | grep -q "[k]smbd.mountd" 2>/dev/null; then
                logger -t router_monitor "WPS: Stoppe ksmbd"
                /etc/init.d/ksmbd stop >/dev/null 2>&1 &
            else
                logger -t router_monitor "WPS: Starte ksmbd"
                /etc/init.d/ksmbd start >/dev/null 2>&1 &
            fi
        fi
        LAST_WPS_STATE="$WPS_STATE"
    fi

    # === 2. WPS-LED: Gast-WLAN Morse-Code (nur alle 10 Sekunden aktualisieren) ===
    if [ -f "/tmp/wifi_client_connecting_wps" ]; then
        sleep 0
    else
        GUEST_DISABLED=$(uci get wireless.wifinet2.disabled 2>/dev/null)
        
        if [ "$GUEST_DISABLED" = "1" ]; then
            echo none > /sys/class/leds/green:wps/trigger
            echo 0 > /sys/class/leds/green:wps/brightness
            MORSE_COUNTER_WPS=0
        else
            # Nur alle 10 Sekunden den Client-Count prüfen (CPU-Optimierung)
            WPS_CLIENT_CHECK_COUNTER=$(($WPS_CLIENT_CHECK_COUNTER + 1))
            if [ "$WPS_CLIENT_CHECK_COUNTER" -ge 10 ]; then
                WPS_CLIENTS_CACHED=$(timeout 2 iw dev phy0-ap1 station dump 2>/dev/null | grep -c "^Station")
                WPS_CLIENT_CHECK_COUNTER=0
                MORSE_COUNTER_WPS=0
            fi
            
            morse_blink_led "/sys/class/leds/green:wps" "$MORSE_COUNTER_WPS" "$WPS_CLIENTS_CACHED"
            MORSE_COUNTER_WPS=$(($MORSE_COUNTER_WPS + 1))
            if [ "$MORSE_COUNTER_WPS" -ge $((WPS_CLIENTS_CACHED * 2 + 2)) ]; then
                MORSE_COUNTER_WPS=0
            fi
        fi
    fi

    # === 3. WLAN-LED: Blinken = Anzahl Clients (Morse-Code, nur alle 10 Sekunden aktualisieren) ===
    if [ -f "/tmp/wifi_client_connecting_wlan" ]; then
        sleep 0
    else
        WLAN_DISABLED=$(uci get wireless.wifinet1.disabled 2>/dev/null)
        
        if [ "$WLAN_DISABLED" = "1" ]; then
            echo none > /sys/class/leds/green:wlan/trigger
            echo 0 > /sys/class/leds/green:wlan/brightness
            MORSE_COUNTER_WLAN=0
        else
            # Nur alle 10 Sekunden den Client-Count prüfen (CPU-Optimierung)
            WLAN_CLIENT_CHECK_COUNTER=$(($WLAN_CLIENT_CHECK_COUNTER + 1))
            if [ "$WLAN_CLIENT_CHECK_COUNTER" -ge 10 ]; then
                WLAN_CLIENTS_CACHED=$(timeout 2 iw dev phy0-ap0 station dump 2>/dev/null | grep -c "^Station")
                WLAN_CLIENT_CHECK_COUNTER=0
                MORSE_COUNTER_WLAN=0
            fi
            
            morse_blink_led "/sys/class/leds/green:wlan" "$MORSE_COUNTER_WLAN" "$WLAN_CLIENTS_CACHED"
            MORSE_COUNTER_WLAN=$(($MORSE_COUNTER_WLAN + 1))
            if [ "$MORSE_COUNTER_WLAN" -ge $((WLAN_CLIENTS_CACHED * 2 + 2)) ]; then
                MORSE_COUNTER_WLAN=0
            fi
        fi
    fi

    # === 4. USB-LED: ksmbd (SMB) Status ===
    if /etc/init.d/ksmbd status >/dev/null 2>&1; then
        # ksmbd läuft - LED an
        echo none > /sys/class/leds/green:usb/trigger
        echo 1 > /sys/class/leds/green:usb/brightness
    else
        # ksmbd nicht aktiv - LED aus
        echo none > /sys/class/leds/green:usb/trigger
        echo 0 > /sys/class/leds/green:usb/brightness
    fi

    # === Check Shutdown Request ===
    if [ -f "/tmp/shutdown_requested" ]; then
        rm -f /tmp/shutdown_requested
        safe_shutdown
    fi

    # === 5. Power/WAN-LED: Internet-Status (Modus-abhängig) ===
    update_internet_leds

    sleep 2
done
