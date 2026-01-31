#!/bin/sh
#
# Router Mode Switch Script
# Wechselt zwischen Hotspot-Modus (5G) und AP-Modus (LAN)
#

TARGET_MODE="$1"
SUBMODE="${2:-lan-only}"

if [ -z "$TARGET_MODE" ]; then
    echo "Usage: $0 <hotspot|ap> [lan-only|lan-fallback|loadbalancing]"
    exit 1
fi

logger -t mode_switch "Switching to mode: $TARGET_MODE ($SUBMODE)"

# Funktion: Hotspot-Modus aktivieren (Internet via 5GHz "iP")
switch_to_hotspot() {
    logger -t mode_switch "Activating Hotspot mode..."
    
    # 1. eth0 zurück in br-lan (via @device[0])
    # Prüfe ob eth0 bereits in der Bridge ist
    CURRENT_PORTS=$(uci get network.@device[0].ports 2>/dev/null)
    if ! echo "$CURRENT_PORTS" | grep -q "eth0"; then
        uci set network.@device[0].ports='eth0'
        logger -t mode_switch "Adding eth0 to br-lan"
    fi
    
    # 2. WAN-Interface erstellen/konfigurieren
    # Prüfe ob WAN-Interface existiert
    if ! uci get network.wan >/dev/null 2>&1; then
        uci set network.wan=interface
        logger -t mode_switch "Creating WAN interface"
    fi
    uci set network.wan.device='wwan'
    uci set network.wan.proto='dhcp'
    
    # 3. Firewall: wwan in WAN-Zone, eth0/br-lan in LAN-Zone
    uci set firewall.@zone[1].network='wan wwan'
    
    # 4. 5GHz Client zu "iP" aktivieren (wifinet0 = wwan)
    uci set wireless.wifinet0.disabled='0'
    logger -t mode_switch "Enabling 5GHz connection to iP (wwan)"
    
    # 5. mwan3 deaktivieren (nicht benötigt im Hotspot-Modus)
    ( sleep 1; /usr/bin/configure_mwan3.sh disable ) >/dev/null 2>&1 &
    
    # 6. Änderungen committen
    uci commit network
    uci commit firewall
    uci commit wireless
    
    # 7. Nur notwendige Services neu starten (weniger disruptiv)
    logger -t mode_switch "Reloading network configuration..."
    ifup wan 2>/dev/null
    /etc/init.d/firewall reload
    wifi reload
    
    logger -t mode_switch "Hotspot mode activated"
}

# Funktion: AP-Modus aktivieren (Internet via eth0)
switch_to_ap() {
    logger -t mode_switch "Activating AP mode (submode: $SUBMODE)..."
    
    # 1. eth0 aus br-lan entfernen (via @device[0])
    uci set network.@device[0].ports=''
    logger -t mode_switch "Removing eth0 from br-lan"
    
    # 2. WAN-Interface erstellen/konfigurieren
    # Prüfe ob WAN-Interface existiert
    if ! uci get network.wan >/dev/null 2>&1; then
        uci set network.wan=interface
        logger -t mode_switch "Creating WAN interface"
    fi
    uci set network.wan.device='eth0'
    uci set network.wan.proto='dhcp'
    
    # 3. Firewall: eth0 in WAN-Zone
    uci set firewall.@zone[1].network='wan'
    
    # 4. Je nach Submode: 5GHz Client zu "iP" (wifinet0 = wwan)
    case "$SUBMODE" in
        lan-only)
            # 5GHz deaktivieren (kein Fallback)
            uci set wireless.wifinet0.disabled='1'
            logger -t mode_switch "Submode: LAN only (5GHz to iP disabled)"
            # mwan3 deaktivieren
            ( sleep 1; /usr/bin/configure_mwan3.sh disable ) >/dev/null 2>&1 &
            ;;
        lan-fallback)
            # 5GHz aktivieren als Fallback
            uci set wireless.wifinet0.disabled='0'
            # Firewall: wwan auch in WAN-Zone für Fallback
            uci set firewall.@zone[1].network='wan wwan'
            logger -t mode_switch "Submode: LAN with 5GHz iP fallback - configuring mwan3"
            ;;
        loadbalancing)
            # 5GHz aktivieren für Load-Balancing
            uci set wireless.wifinet0.disabled='0'
            # Firewall: wwan auch in WAN-Zone
            uci set firewall.@zone[1].network='wan wwan'
            logger -t mode_switch "Submode: LAN + 5GHz iP load-balancing - configuring mwan3"
            ;;
    esac
    
    # 5. Änderungen committen
    uci commit network
    uci commit firewall
    uci commit wireless
    
    # 6. Nur notwendige Services neu laden (weniger disruptiv)
    logger -t mode_switch "Reloading network configuration..."
    ifdown wan 2>/dev/null
    sleep 1
    ifup wan
    /etc/init.d/firewall reload
    wifi reload
    
    # 7. Nach Network-Reload: mwan3 konfigurieren (falls benötigt)
    if [ "$SUBMODE" = "lan-fallback" ]; then
        ( sleep 5; /usr/bin/configure_mwan3.sh lan-fallback ) &
    elif [ "$SUBMODE" = "loadbalancing" ]; then
        ( sleep 5; /usr/bin/configure_mwan3.sh loadbalancing ) &
    fi
    
    logger -t mode_switch "AP mode activated"
}

# Mode-Switch ausführen
case "$TARGET_MODE" in
    hotspot)
        switch_to_hotspot
        ;;
    ap)
        switch_to_ap
        ;;
    *)
        echo "Invalid mode: $TARGET_MODE"
        echo "Valid modes: hotspot, ap"
        exit 1
        ;;
esac

exit 0
