include loader.fs \sds
include dns.fs

: preip-handler
    begin
        mac-fullness
    while
        OFFSET_ETH_TYPE packet@ h# 800 = if
            dhcp-wait-offer
        then
        mac-consume
    repeat
;

: haveip-handler
    \ time@ begin ether_irq @ until time@ 2swap d- d. cr
    \ begin ether_irq @ until
    begin
        mac-fullness
    while
        arp-handler
        OFFSET_ETH_TYPE packet@ h# 800 =
        if
            d# 2 OFFSET_IP_DSTIP mac-inoffset mac@n net-my-ip d=
            if
                icmp-handler
            then
            loader-handler \ sds
        then
        depth if .s cr then
        mac-consume
    repeat
;


