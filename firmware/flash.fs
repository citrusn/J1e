( SPI: Serial Peripheral Interface           JCB 13:14 08/24/10)
module[ spi"

: flash-reset
    flash_rst_n   off
    flash_rst_n   on
;

: flash-cold
    flash_ddir    on
    flash_ce_n    off
    flash_oe_n    on
    flash_we_n    on
    flash_byte_n  on
    flash_rdy     on
    flash-reset
;

: flash-w ( u a -- )
    flash_a !
    flash_d !
    flash_ddir off
    flash_we_n off
    flash_we_n on
    flash_ddir on
;

: flash-r ( a -- u )
    flash_a !
    flash_oe_n off
    flash_d @
    flash_oe_n on
;

: flash-unlock ( -- )
    h# aa h# 555 flash-w
    h# 55 h# 2aa flash-w
;

: flash! ( u da. -- )
    flash-unlock
    h# a0 h# 555 flash-w
    flash_a 2+ !    ( u a )
    2dup            ( u a u a)
    flash-w         ( u a )
    begin
        2dup flash-r xor
        h# 80 and 0=
    until
    2drop
    flash-reset
;

: flash@ ( da. -- u )
    flash_a 2+ !    ( u a )
    flash-r
;

: flash-chiperase
    flash-unlock
    h# 80 h# 555 flash-w
    h# aa h# 555 flash-w
    h# 55 h# 2aa flash-w
    h# 10 h# 555 flash-w
;

: flash-sectorerase ( da -- ) \ erase one sector
    flash-unlock
    h# 80 h# 555 flash-w
    h# aa h# 555 flash-w
    h# 55 h# 2aa flash-w
    flash_a 2+ ! h# 30 swap flash-w
;

: flash-erased ( a -- f )
    flash@ h# 80 and 0<> ;

: flash-dump ( da u -- )
    0do
        2dup flash@ hex4 space
        d1+
    loop cr
    2drop
;

: flashc@
    over d# 15 lshift flash_d !
    d2/ flash@
;

: flash-bytes
    s" BYTES: " type
    flash_byte_n  off
    h# 0.
    d# 1024 0do
        i d# 15 and 0= if
            cr
            2dup hex8 space space
        then
        2dup flashc@ hex2 space
        d1+
    loop cr
    2drop
    flash_byte_n  on
;


0 [IF]
: flash-demo
    flash-unlock
    h# 90 h# 555 flash-w
    h# 00 flash-r hex4 cr
    flash-reset

    false if
        flash-unlock
        h# a0 h# 555 flash-w
        h# 0947 h# 5 flash-w
        sleep1
        flash-reset
    then

    \ h# dead d# 11. flash!

    h# 100 0do
        i flash-r hex4 space
    loop cr
    cr cr
    d# 0. h# 80 flash-dump
    cr cr

    flash-bytes

    exit
    flash-unlock
    h# 80 h# 555 flash-w
    h# aa h# 555 flash-w
    h# 55 h# 2aa flash-w
    h# 10 h# 555 flash-w
    s" waiting for erase" type cr
    begin
        h# 0 flash-r dup hex4 cr
        h# 80 and
    until

    h# 100 0do
        i flash-r hex4 space
    loop cr
;
[THEN]

: flash>ram ( d. a -- ) \ copy 2K from flash d to a
    >r d2/ r>
    d# 1024 0do
        >r
        2dup flash@
        r> ( d. u a )
        over swab over !
        1+
        tuck !
        1+
        >r d1+ r>
    loop
    drop 2drop
;

: frob
    flash_ce_n    on
    flash_ddir off
    d# 32 0do
        d# 1 i d# 7 and lshift
        flash_d !
        d# 30000. sleepus
    loop
    flash_ddir on
;


]module 