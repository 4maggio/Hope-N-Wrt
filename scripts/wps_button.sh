#!/bin/sh

[ "${ACTION}" = "released" ] || exit 0

CLICK_FILE="/tmp/wps_click_count"
CLICK_WINDOW=800
NOW=$(date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000)))

# Schalterposition lesen
if cat /sys/kernel/debug/gpio | grep "sw1" | grep -q " lo "; then
    SW1=0
else
    SW1=1
fi

if cat /sys/kernel/debug/gpio | grep "sw2" | grep -q " lo "; then
    SW2=0
else
    SW2=1
fi

POSITION="${SW1}${SW2}"

# Click-Zähler initialisieren/updaten
if [ -f "$CLICK_FILE" ]; then
    read LAST_TIME CLICK_COUNT < $CLICK_FILE
    TIME_DIFF=$((NOW - LAST_TIME))
    
    if [ $TIME_DIFF -le $CLICK_WINDOW ]; then
        CLICK_COUNT=$((CLICK_COUNT + 1))
    else
        CLICK_COUNT=1
    fi
else
    CLICK_COUNT=1
fi

echo "$NOW $CLICK_COUNT" > $CLICK_FILE

logger -t wps_button "Click #$CLICK_COUNT in Position $POSITION"

# Warte auf weitere Clicks oder führe Aktion aus
(
    sleep 1
    
    if [ ! -f "$CLICK_FILE" ]; then
        exit 0
    fi
    
    read STORED_TIME FINAL_COUNT < $CLICK_FILE
    
    if [ "$STORED_TIME" != "$NOW" ]; then
        exit 0
    fi
    
    rm -f $CLICK_FILE
    
    logger -t wps_button "Executing action: $FINAL_COUNT clicks in position $POSITION"
    
    # === Aktionen basierend auf Position und Clicks ===
    
    # Position "01" (Router Settings): 1x=AP Submode, 2x=Router Mode
    if [ "$POSITION" = "01" ]; then
        MODE=$(uci get router_mode.config.router_mode 2>/dev/null || echo "hotspot")
        
        if [ "$FINAL_COUNT" = "1" ]; then
            # Cycle AP Submode (nur wenn im AP-Modus)
            if [ "$MODE" = "ap" ]; then
                logger -t wps_button "Cycle AP Submode"
                
                # WAN-LED schnell blinken
                echo timer > /sys/class/leds/green:wan/trigger
                echo 100 > /sys/class/leds/green:wan/delay_on
                echo 100 > /sys/class/leds/green:wan/delay_off
                
                SUBMODE=$(uci get router_mode.config.ap_submode 2>/dev/null || echo "lan-only")
                
                if [ "$SUBMODE" = "lan-only" ]; then
                    NEW_SUBMODE="lan-fallback"
                elif [ "$SUBMODE" = "lan-fallback" ]; then
                    NEW_SUBMODE="loadbalancing"
                else
                    NEW_SUBMODE="lan-only"
                fi
                
                uci set router_mode.config.ap_submode="$NEW_SUBMODE"
                uci commit router_mode
                logger -t wps_button "AP Submode: $NEW_SUBMODE"
                
                # Direkt konfigurieren ohne volles Network-Reload
                case "$NEW_SUBMODE" in
                    "lan-only")
                        # 5GHz deaktivieren, mwan3 aus
                        uci set wireless.wifinet0.disabled='1'
                        uci commit wireless
                        wifi reload
                        ( sleep 2; /usr/bin/configure_mwan3.sh disable ) >/dev/null 2>&1 &
                        ;;
                    "lan-fallback")
                        # 5GHz an, mwan3 fallback
                        uci set wireless.wifinet0.disabled='0'
                        uci set firewall.@zone[1].network='wan wwan'
                        uci commit wireless
                        uci commit firewall
                        wifi reload
                        /etc/init.d/firewall reload
                        ( sleep 5; /usr/bin/configure_mwan3.sh lan-fallback ) >/dev/null 2>&1 &
                        ;;
                    "loadbalancing")
                        # 5GHz an, mwan3 load-balancing
                        uci set wireless.wifinet0.disabled='0'
                        uci set firewall.@zone[1].network='wan wwan'
                        uci commit wireless
                        uci commit firewall
                        wifi reload
                        /etc/init.d/firewall reload
                        ( sleep 5; /usr/bin/configure_mwan3.sh loadbalancing ) >/dev/null 2>&1 &
                        ;;
                esac
                
                sleep 1
            else
                logger -t wps_button "Not in AP mode - submode not available"
            fi
            
        elif [ "$FINAL_COUNT" -ge "2" ]; then
            # Toggle Router Mode
            logger -t wps_button "Toggle Router Mode"
            
            # Power-LED schnell blinken
            echo timer > /sys/class/leds/green:power/trigger
            echo 100 > /sys/class/leds/green:power/delay_on
            echo 100 > /sys/class/leds/green:power/delay_off
            
            if [ "$MODE" = "hotspot" ]; then
                NEW_MODE="ap"
                NEW_SUBMODE="lan-only"
                uci set router_mode.config.router_mode="$NEW_MODE"
                uci set router_mode.config.ap_submode="$NEW_SUBMODE"
                uci commit router_mode
                logger -t wps_button "Router Mode: AP (lan-only)"
                
                # Netzwerk umkonfigurieren
                /usr/bin/switch_router_mode.sh ap lan-only &
            else
                NEW_MODE="hotspot"
                uci set router_mode.config.router_mode="$NEW_MODE"
                uci commit router_mode
                logger -t wps_button "Router Mode: Hotspot"
                
                # Netzwerk umkonfigurieren
                /usr/bin/switch_router_mode.sh hotspot &
            fi
            
            sleep 1
        fi
        
    # Position "10" (WLAN Settings): 1x=WLAN 0, 2x=Guest WLAN
    elif [ "$POSITION" = "10" ]; then
        if [ "$FINAL_COUNT" = "1" ]; then
            logger -t wps_button "Toggle WLAN 0"
            
            # WLAN-LED schnell blinken
            echo timer > /sys/class/leds/green:wlan/trigger
            echo 100 > /sys/class/leds/green:wlan/delay_on
            echo 100 > /sys/class/leds/green:wlan/delay_off
            
            DISABLED=$(uci get wireless.wifinet1.disabled 2>/dev/null)
            if [ "$DISABLED" = "1" ]; then
                uci set wireless.wifinet1.disabled='0'
                logger -t wps_button "WLAN '0' aktiviert"
            else
                uci set wireless.wifinet1.disabled='1'
                logger -t wps_button "WLAN '0' deaktiviert"
            fi
            uci commit wireless
            wifi reload
            
            sleep 2
            
        elif [ "$FINAL_COUNT" -ge "2" ]; then
            logger -t wps_button "Toggle Guest WLAN"
            
            # WPS-LED schnell blinken
            echo timer > /sys/class/leds/green:wps/trigger
            echo 100 > /sys/class/leds/green:wps/delay_on
            echo 100 > /sys/class/leds/green:wps/delay_off
            
            DISABLED=$(uci get wireless.wifinet2.disabled 2>/dev/null)
            if [ "$DISABLED" = "1" ]; then
                uci set wireless.wifinet2.disabled='0'
                logger -t wps_button "Gast-WLAN aktiviert"
            else
                uci set wireless.wifinet2.disabled='1'
                logger -t wps_button "Gast-WLAN deaktiviert"
            fi
            uci commit wireless
            wifi reload
            
            sleep 2
        fi
        
    # Position "11" (USB Settings/System): 1x=USB Share, 2x=Shutdown
    elif [ "$POSITION" = "11" ]; then
        if [ "$FINAL_COUNT" = "1" ]; then
            logger -t wps_button "Toggle USB Share"
            
            # USB-LED schnell blinken
            echo timer > /sys/class/leds/green:usb/trigger
            echo 100 > /sys/class/leds/green:usb/delay_on
            echo 100 > /sys/class/leds/green:usb/delay_off
            
            if /etc/init.d/lighttpd status >/dev/null 2>&1; then
                /etc/init.d/lighttpd stop
                logger -t wps_button "WebDAV deaktiviert"
                sleep 1
                echo none > /sys/class/leds/green:usb/trigger
                echo 0 > /sys/class/leds/green:usb/brightness
            else
                /etc/init.d/lighttpd start
                logger -t wps_button "WebDAV aktiviert"
                sleep 1
                echo none > /sys/class/leds/green:usb/trigger
                echo 1 > /sys/class/leds/green:usb/brightness
            fi
            
        elif [ "$FINAL_COUNT" -ge "2" ]; then
            logger -t wps_button "SHUTDOWN initiiert"
            
            for led in wlan wps wan usb power; do
                echo timer > /sys/class/leds/green:$led/trigger
                echo 100 > /sys/class/leds/green:$led/delay_on
                echo 100 > /sys/class/leds/green:$led/delay_off
            done
            
            sleep 2
            killall -USR1 nlbwmon 2>/dev/null
            sleep 1
            sync
            poweroff
        fi
    fi
    
) &

exit 0
