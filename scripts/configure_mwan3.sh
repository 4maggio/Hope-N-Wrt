#!/bin/sh
#
# mwan3 Konfiguration für Multi-WAN Setup
# Modi: lan-fallback (wan primär, wwan backup) und loadbalancing (beide gleichzeitig)
#

MODE="$1"

if [ -z "$MODE" ]; then
    echo "Usage: $0 <lan-fallback|loadbalancing|disable>"
    exit 1
fi

logger -t mwan3_config "Configuring mwan3 for mode: $MODE"

case "$MODE" in
    lan-fallback)
        logger -t mwan3_config "Setting up LAN with 5G fallback"
        
        # Interfaces definieren
        uci set mwan3.wan=interface
        uci set mwan3.wan.enabled='1'
        uci set mwan3.wan.initial_state='online'
        uci set mwan3.wan.family='ipv4'
        uci set mwan3.wan.track_method='ping'
        uci set mwan3.wan.track_ip='1.1.1.1' '8.8.8.8'
        uci set mwan3.wan.reliability='1'
        uci set mwan3.wan.count='1'
        uci set mwan3.wan.size='56'
        uci set mwan3.wan.max_ttl='60'
        uci set mwan3.wan.timeout='4'
        uci set mwan3.wan.interval='10'
        uci set mwan3.wan.failure_interval='5'
        uci set mwan3.wan.recovery_interval='5'
        uci set mwan3.wan.down='3'
        uci set mwan3.wan.up='3'
        
        uci set mwan3.wwan=interface
        uci set mwan3.wwan.enabled='1'
        uci set mwan3.wwan.initial_state='online'
        uci set mwan3.wwan.family='ipv4'
        uci set mwan3.wwan.track_method='ping'
        uci set mwan3.wwan.track_ip='1.1.1.1' '8.8.8.8'
        uci set mwan3.wwan.reliability='1'
        uci set mwan3.wwan.count='1'
        uci set mwan3.wwan.size='56'
        uci set mwan3.wwan.max_ttl='60'
        uci set mwan3.wwan.timeout='4'
        uci set mwan3.wwan.interval='10'
        uci set mwan3.wwan.failure_interval='5'
        uci set mwan3.wwan.recovery_interval='5'
        uci set mwan3.wwan.down='3'
        uci set mwan3.wwan.up='3'
        
        # Members (wan höhere Priorität als wwan für Fallback)
        uci set mwan3.wan_m1_w3=member
        uci set mwan3.wan_m1_w3.interface='wan'
        uci set mwan3.wan_m1_w3.metric='1'
        uci set mwan3.wan_m1_w3.weight='3'
        
        uci set mwan3.wwan_m2_w1=member
        uci set mwan3.wwan_m2_w1.interface='wwan'
        uci set mwan3.wwan_m2_w1.metric='2'
        uci set mwan3.wwan_m2_w1.weight='1'
        
        # Policy für Fallback (wan primär, wwan als backup)
        uci set mwan3.wan_wwan=policy
        uci set mwan3.wan_wwan.last_resort='unreachable'
        uci add_list mwan3.wan_wwan.use_member='wan_m1_w3'
        uci add_list mwan3.wan_wwan.use_member='wwan_m2_w1'
        
        # Rule für alle Pakete
        uci set mwan3.default_rule=rule
        uci set mwan3.default_rule.dest_ip='0.0.0.0/0'
        uci set mwan3.default_rule.use_policy='wan_wwan'
        uci set mwan3.default_rule.proto='all'
        uci set mwan3.default_rule.sticky='0'
        
        uci commit mwan3
        logger -t mwan3_config "Fallback configuration done"
        ;;
        
    loadbalancing)
        logger -t mwan3_config "Setting up load balancing"
        
        # Interfaces definieren (gleich wie fallback)
        uci set mwan3.wan=interface
        uci set mwan3.wan.enabled='1'
        uci set mwan3.wan.initial_state='online'
        uci set mwan3.wan.family='ipv4'
        uci set mwan3.wan.track_method='ping'
        uci set mwan3.wan.track_ip='1.1.1.1' '8.8.8.8'
        uci set mwan3.wan.reliability='1'
        uci set mwan3.wan.count='1'
        uci set mwan3.wan.size='56'
        uci set mwan3.wan.max_ttl='60'
        uci set mwan3.wan.timeout='4'
        uci set mwan3.wan.interval='10'
        uci set mwan3.wan.failure_interval='5'
        uci set mwan3.wan.recovery_interval='5'
        uci set mwan3.wan.down='3'
        uci set mwan3.wan.up='3'
        
        uci set mwan3.wwan=interface
        uci set mwan3.wwan.enabled='1'
        uci set mwan3.wwan.initial_state='online'
        uci set mwan3.wwan.family='ipv4'
        uci set mwan3.wwan.track_method='ping'
        uci set mwan3.wwan.track_ip='1.1.1.1' '8.8.8.8'
        uci set mwan3.wwan.reliability='1'
        uci set mwan3.wwan.count='1'
        uci set mwan3.wwan.size='56'
        uci set mwan3.wwan.max_ttl='60'
        uci set mwan3.wwan.timeout='4'
        uci set mwan3.wwan.interval='10'
        uci set mwan3.wwan.failure_interval='5'
        uci set mwan3.wwan.recovery_interval='5'
        uci set mwan3.wwan.down='3'
        uci set mwan3.wwan.up='3'
        
        # Members (gleiche Metrik für Load Balancing)
        uci set mwan3.wan_m1_w2=member
        uci set mwan3.wan_m1_w2.interface='wan'
        uci set mwan3.wan_m1_w2.metric='1'
        uci set mwan3.wan_m1_w2.weight='2'
        
        uci set mwan3.wwan_m1_w1=member
        uci set mwan3.wwan_m1_w1.interface='wwan'
        uci set mwan3.wwan_m1_w1.metric='1'
        uci set mwan3.wwan_m1_w1.weight='1'
        
        # Policy für Load Balancing (beide gleichzeitig, gleiche Metrik)
        uci set mwan3.balanced=policy
        uci set mwan3.balanced.last_resort='default'
        uci add_list mwan3.balanced.use_member='wan_m1_w2'
        uci add_list mwan3.balanced.use_member='wwan_m1_w1'
        
        # Rule für alle Pakete
        uci set mwan3.default_rule=rule
        uci set mwan3.default_rule.dest_ip='0.0.0.0/0'
        uci set mwan3.default_rule.use_policy='balanced'
        uci set mwan3.default_rule.proto='all'
        uci set mwan3.default_rule.sticky='0'
        
        uci commit mwan3
        logger -t mwan3_config "Load balancing configuration done"
        ;;
        
    disable)
        logger -t mwan3_config "Disabling mwan3"
        /etc/init.d/mwan3 stop
        /etc/init.d/mwan3 disable
        logger -t mwan3_config "mwan3 disabled"
        exit 0
        ;;
        
    *)
        echo "Invalid mode: $MODE"
        exit 1
        ;;
esac

# Starte/Restarte mwan3
/etc/init.d/mwan3 enable
/etc/init.d/mwan3 restart

logger -t mwan3_config "mwan3 service restarted"
