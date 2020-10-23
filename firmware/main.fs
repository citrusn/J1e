( Main for WGE firmware                      JCB 13:24 08/24/10)
( 
  память:
    16 кб - 8кБ х 16 бит
    адрес памяти 0 - 3FFFh  
  flash:
    180000 2k to 8000 экранная   
    180800 2k to f000 знакогенератор
    190000 16к to 0 программа
    200000 16к to 0(0..7(7.png 16 спрайтов ["%d.png" % (i/2 for i in range(16]
        welcome-main
    204000 16к to blob.png 16 спрайтов  ["blob.png"] * 16
        stars-main
    208000 16к to fsm-32.png pop.png fsm-32.png pop.png fsm-32.png pop.png  
                  bomb.png   pop.png shot.png   pop.png
        invaders-cold
  спрайт:
    8 штук 
    2 кБ один спрайт х 8 бит
    размер спрайта 32 х 32 пикселя
    адрес памяти
    4302h выбор спрайта и хранение адреса для записи
    h# 4302 constant vga_spritea
    4304h для записи данных в область спрайта
    h# 4304 constant vga_spriteport
  экран:
    2кБ х 8 бит
    адрес памяти 8000-87FF
    режим экрана 800х600х72 Герц
    64 символа в ширину, отображается только 50
    высота 512 пикселей 40 строк
  знакогенератор:
    2 кБ х 8 бит
    адрес памяти F000-F7FF
    8х8 точек в символе
    число символов - 256 )

(   2к знакогенератор русс язык     с 10 сектора +
    2к знакогенератор под логотип   с 15 сектора +
    2к экран логотипа               с 20 сектора +
    16к спрайты 16 цифр по 1 кб     с 25 сектора +
    16к спрайты 16 blob по 1 кб     с 70 сектора +
    16к спрайты 16 inv  по 1 кб     с 110 сектора +
    2к psg звук combat 6            с 170 сектора +
)

\ warnings off
\ require tags.fs

include crossj1.fs
meta
    : TARGET? 1 ;
    : build-debug? 1 ;

include basewords.fs
target
include hwdefs.fs

include bootloader.fs

4 org
module[ everything"
include nuc.fs

include version.fs

: frac ( ud u -- d1 u1 ) \ d1+u1 is ud
    >r 2dup d# 1 r@ m*/ 2swap 2over r> d# 1 m*/ d- drop 
;
: .2  s>d <# # # #> type ;
: build.
    decimal
    builddate drop
    [ -8 3600 * ] literal s>d d+
    d# 1 d# 60 m*/mod >r
    d# 1 d# 60 m*/mod >r
    d# 1 d# 24 m*/mod >r
    2drop
    r> .2 [char] : emit
    r> .2 [char] : emit
    r> .2 ;

\ : net-my-mac h# 1234 h# 5677 h# 7777 ; \ sds
include doc.fs \ sds
include time.fs
\ include eth-ax88796.fs \ sds
\ include packet.fs \ sds
\ include ip0.fs \ sds
\ include defines_tcpip.fs \ sds
\ include defines_tcpip2.fs \ sds
\ include arp.fs \ sds
\ include ip.fs \ sds
\ include udp.fs \ sds
\ include dhcp.fs \ sds

include spi.fs \ sds
include ay8910.fs
\ include flash.fs \ sds
include sprite.fs
include uart.fs

: sd>memory ( buffer block n -- )
    \ для экрана и знакогенератора
    \ читаем один байт с карты и пишем его 
    \ в память 8 битную
    'sd-read-bytes @ >r
    ['] sd-read-IO 'sd-read-bytes !
    0do 
        2dup ( buffer block buffer block )
        s>d sd-read-block ( buffer block )
        1+ swap d# 512 + swap ( buffer+512 block+1 )
    loop
    2drop 
    r> 'sd-read-bytes !
;

include vga.fs
( Demo utilities                             JCB 10:56 12/05/10)

: statusline ( a u -- ) \ display string on the status line
    d# 0 d# 31 2dup vga-at-xy
    d# 50 spaces
    vga-at-xy type
;

( Game stuff                                 JCB 15:20 11/15/10)

variable seed
: random  ( -- u )
    seed @ d# 23947 * d# 57711 xor dup seed ! ;   

\ Each line is 20.8 us, so 1000 instructions

include sincos.fs
include stars.fs

\ : loadsprites \ ( da -- )
\    2/
\    d# 16384 0do
\        \ 2dup i s>d d+ flash@ \ sds
\        i vga_spritea !  vga_spriteport !
\    loop
\   2drop ; 
: loadsprites ( block -- )
    'sd-read-bytes @ >r
    ['] sd-read-sprite 'sd-read-bytes !
    
    d# 32 0do \ 8 спрайтов по 2 кб
        dup ( block block )
        d# 512 i * ( block block adr )
        swap s>d sd-read-block ( block )        
        1+
    loop
    drop
    r> 'sd-read-bytes !
;
\ include ip-handlers.fs \sds

variable prev_sw3_n
: next? ( -- f ) \ has user requested next screen
     sw3_n @ prev_sw3_n fall? ;

variable prev_sw2_n
: sw2?  sw2_n @ prev_sw2_n fall? ;

include ps2kb.fs

: istab? ( -- f )
    key? dup if         
        key TAB = and 
    then ;

: isesc1? ( -- f )
    key? dup if         
        key ESC = and 
    then ;

: buttons ( -- u ) \ pb4 pb3 pb2
    ( pb_a_dir on
    pb_a @ d# 7 xor
    pb_a_dir off )
    
    key? if key
        dup KLEFT  = if drop pb2 else 
        dup KRIGHT = if drop pb3 else
            KUP    = if      pb4 else
        d# 0 then then then 
    else d# 0   
    then ;

include invaders.fs

: stars-main
    vga-page
    d# 70 loadsprites \ blob.png
    \ d# 16384 0do \ sds
    \    h# 204000. 2/ i s>d d+ flash@
    \    i vga_spritea !  vga_spriteport !
    \ loop

    \ vga_addsprites on \ not wrking sds
    rainbow    

    time@ xor seed !
    seed off
     scatterSpiral
    \ scatterR
    \ scatter

    depth if snap drop pause then
    d# 7000000. vision setalarm
    d# 0 frame !    
    begin
        makedl
        stars-chasebeam
        
        \ d# 256 0do i i plot loop
        \ rotateall
        frame @ 1+ frame !       
        istab?  
        next? or
    until
    depth if snap drop pause then
    frame @ . s"  frames" type cr
    sleep1
    \ pause
;
: net-my-ip h# 12345678. ; \ fict ip
: #ip1  h# ff and s>d #s 2drop ;
: #.    [char] . hold ;
: #ip2  dup #ip1 #. d# 8 rshift #ip1 ;
: #ip   ( ip -- c-addr u) dup #ip2 #. over #ip2 ;

: welcome-main
  depth if snap then      
    vga-cold    
    home
    'emit @ >r
    ['] vga-emit 'emit !

    s" F1 to set up network, TAB for next demo" statusline
  depth if snap then

    rainbow
    d# 25 loadsprites \ h# 200000. loadsprites    
    
    d# 6 d# 26 vga-at-xy s" Softcore Forth CPU" type

    d# 32 d# 6 vga-at-xy  s" version " type version type
    d# 32 d# 8 vga-at-xy  s" built   " type build.

    \ kb-cold
    home    
  depth if snap then
    begin
        \ kbfifo-proc          
    depth if snap then
        d# 32 d# 10 vga-at-xy net-my-ip <# #ip #> type space space
    depth if snap then
        d# 32 d# 12 vga-at-xy s" uptime  " type uptime d.
        \ haveip-handler
    depth if snap then    
        d# 8 0do
            frame @ i d# 32 * + invert >r
            d# 100 r@ sin* d# 600 +
            d# 100 r> cos* d# 334 +
            i sprite!
        loop 
    depth if snap then   
        waitblank
        d# 1 frame +!        
 
        next?
        istab? or
    until
  depth if snap then
    r> 'emit !
;
\ include clock.fs \ sds
: sd-test \ тест сд карты
    cr cr  s" start " type
    \ sd-cold \ depth .  
    s" sd-cold " type 
    \ depth .  cr
    buffer h# 00000000. sd-read-block  
    s" sd-read 0 block " type 
    \ depth .  cr
    buffer d# 512 dump
    hex buffer @ . cr 
    s" sd-write 8 block " type
    h# 00000008. sd-write-block
    s" sd-read 8 block " type cr
    buffer h# 00000008. sd-read-block  
    buffer d# 512 dump
;
: kbd-test
    begin 
        key dup [char] q = if
            drop s" exit" type
            exit \ выход не понятно только куда..
                \ к следующему слову перехода нет
        then 
        emit
    again
    \ begin key? curkey emit  again
;
: uart-test
  ['] serout 'emit !
  begin
    ser? if
      serin emit
      \ [char] q = if exit then
      then
  again 
;
: ay-test ( -- )
  begin              
    key [char] z = if ay-shot then
  again
;
: vga-bigemit-test
  depth if snap then
    \ vga-cold
    [char] ? vga-emit
    [char] B vga-emit
    [char] C vga-emit
  depth if snap then
    ['] vga-bigemit 'emit ! \ sds
    \ ['] serout 'emit !
    s" HELLO" type
    \ depth if snap then
    \ [char] ?  vga-bigemit
    \ depth if snap then
    \ [char] @  vga-bigemit
    \ depth if snap then
    \ [char] A  vga-bigemit 
    \ depth if snap then
    \ коды >=128 русские буквы
    h# 80 vga-emit h# 87 vga-emit d# 159 vga-emit cr
    'emit @ >r
    ['] vga-emit 'emit !
    s" привет hello" type \ не работает
    r> 'emit !
  depth if snap then
;
: j1-logo ( -- )
    s" j1-logo" type cr
    h# f000 d# 15 d# 2 sd>memory \ знакогенератор
    h# 8000 d# 20 d# 4 sd>memory \  экранная память
    \ chars-table-cold \ вернуть как было не выйдет сразу
;
include uart-handler.fs
: main
    decimal    
    ['] serout 'emit !
    ['] sd-read-MEM 'sd-read-bytes !     
    dropall
    sleep.1

    ay-cold
depth if snap then
    sd-cold \ инициализация сд карты
depth if snap then    
    vga-cold
depth if snap then    
    kb-cold

    d# 6 0do cr loop
depth if snap then    
    s" Welcome! Built " type build. cr 
    s" uart:" type serready .  serin . cr
    snap
    \ begin again
    \ frob \ sds    
 
    \ j1-logo
    \ key drop
    \ ay-test
    \ ay-shot sleep1    
     begin uart-handler again
    \ d# 170 play-psg
    \ chars-table-cold
    \ sd-test 
    \ uart-test
    \ kbd-test
    \ vga-bigemit-test
    \ key drop
    \ flash-cold
    \ flash-demo
    \ flash-bytes
    
    \ vga-cold
    ['] vga-emit 'emit !
    s" Waiting for Ethernet NIC" statusline
     \ begin again \ sds

   (
    mac-cold
    nicwork
    h# decafbad. dhcp-xid!
    d# 3000000. dhcp-alarm setalarm
    false if
        ip-addr dz
        begin
            net-my-ip d0=
        while
            dhcp-alarm isalarm if
                dhcp-discover
                s" DISCOVER" type cr
                d# 3000000. dhcp-alarm setalarm
            then
            preip-handler
        repeat
    else
        ip# 192.168.0.99 ip-addr 2!
        ip# 255.255.255.0 ip-subnetmask 2!
        ip# 192.168.0.1 ip-router 2!
        \ ip# 192.168.2.201 ip-addr 2!
        \ ip# 255.255.255.0 ip-subnetmask 2!
        \ ip# 192.168.2.1 ip-router 2!
    then
    dhcp-status
    arp-reset )
    
    depth if snap then
    pause
    depth if snap then
    ( begin
        \ welcome-main        sleep.1
        \ depth if snap drop pause then
        \ clock-main          sleep.1
        \ stars-main          sleep.1
         depth if snap drop pause then
         invaders-main       sleep.1
        s" looping" type cr
        sleep1
    again )

    begin
       \ haveip-handler
    again
;


]module

0 org

code 0jump
    \ h# 3e00 ubranch
    main ubranch
    main ubranch
end-code

meta

hex

: create-output-file w/o create-file throw to outfile ;

\ .mem is a memory dump formatted for use with the Xilinx
\ data2mem tool.
s" j1.mem" create-output-file
:noname
    s" @ 20000" type cr
    4000 0 do i t@ s>d <# # # # # #> type cr 2 +loop
; execute

\ .bin is a big-endian binary memory dump
s" j1.bin" create-output-file
:noname 4000 0 do i t@ dup 8 rshift emit emit 2 +loop ; execute

\ .lst file is a human-readable disassembly 
s" j1.lst" create-output-file
d# 0
h# 2000 disassemble-block
