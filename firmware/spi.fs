( SPI: Serial Peripheral Interface           JCB 13:14 08/24/10)
module[ spi"

: spix  ( x -- y )
    d# 8 lshift
    d# 8 0do
        dup 0< spi_mosi !
        d# 1 spi_sck !
        2* spi_miso @ or
        d# 0 spi_sck !
    loop
;
: spi-wr        spix drop ;
: spi-rd        h# ff spix ;
: spi-dummy     spi-rd drop ;
: spi-rd16      spi-rd d# 8 lshift spi-rd or ;
\ : spi-rd16be     spi-rd spi-rd d# 8 lshift or ; \ sds
: spi-wr16      dup d# 8 rshift spi-wr spi-wr ;
\ : spi-wr16be     dup spi-wr d# 8 rshift spi-wr ; \ sds
: spi-wrbuf     ( addr u -- ) 
    0do dup @ spi-wr16 2+ loop drop ;

\ data token for CMD9, CMD17, CMD18 and CMD24 are the same
h# fe constant DATA_TOKEN_CMD9
h# fe constant DATA_TOKEN_CMD17
h# fe constant DATA_TOKEN_CMD18
h# fe constant DATA_TOKEN_CMD24
h# fc constant DATA_TOKEN_CMD25

create buffer 512 allot

: emit-uart1 drop ;
create 'sd-read-bytes
 meta emit-uart1 t, target
: sd-read-bytes 'sd-read-bytes @ execute ;

create CMD0 
    h# 4000 ( CMD0 ) , ( h# 0 , )
    h# 0 , ( h# 0  , )
    ( h# 0 ) ( ARG = 0 , )
    h# 0095 ( CRC7 + end bit ) , 

create CMD8   
    h# 4800 ( CMD8 ) , ( h# 0 , )
    h# 0001 , ( h# 1 , )
    ( h# aa ( ARG , )
    h# aa87 ( CRC7 + end bit ) ,

create CMD55
    h# 7700 ( CMD55 ) , ( h# 0 , )
    h# 00 , ( h# 0 , )
    ( h# 0 ( ARG  , )
    h# 00001 ( CRC7 + end bit ) ,

create ACMD41
    h# 6940 ( ACMD41 ) , ( h# 40 , )
    h# 00 , ( h# 0 , )
    ( h# 0 ( ARG  , )
    h# 0001 ( CRC7 + end bit ) ,

create CMD58
    h# 7a00 ( CMD58 ) , ( h# 0 , )
    h# 00 , ( h# 0 , )
    ( h# 0 ( ARG  , )
    h# 0001 ( CRC7 + end bit ) ,


: sd-readR1 ( -- r1) 
    h# FF spix \ must be FF
;
: sd-dummy ( -- ) 
    h# FF spix drop \ must be FF
;
\ читаем два байта в одно 16 битное слово
: sd-read-MEM ( buff buff_size -- )    
    \ только четное число байт
    d# 1 rshift \ 1024
    \ over . dup . 
    0do
        dup \ адрес
        \ spi-rd spi-rd d# 8 lshift or
        spi-rd16
        swap !
        d# 2 +
    loop
    drop
;
\ читаем один байт в одно 8 битное слово памяти ВВ
: sd-read-IO ( buff buff_size -- )       
    0do 
        dup ( buff buff )     
        spi-rd
        swap ! 
        d# 1 +
    loop    
    drop 
;
\ читаем сектор с карты в память спрайта
: sd-read-sprite ( adr_spr buff_size -- )
    \ snap
    0do
        dup ( adr adr )
        spi-rd ( adr adr u ) 
        swap ( adr u adr ) 
        vga_spritea !  vga_spriteport ! ( adr )
        d# 1 +        
    loop    
    drop 
;
\ в одном слове два байта значимы
: sd-write-2bytes ( buff buff_size -- )     
    \ только четное число байт
    d# 1 rshift
    0do 
        dup @ \ 16 бит из буфера
        \ dup d# 8 rshift spi-wr spi-wr \ посылка 2 байтов        
        spi-wr16
        d# 2 +
    loop
    drop
;
\ в одном слове один байт значимый
: sd-write-1byte ( buff buff_size -- )
    0do
        dup @
        spi-wr
        d# 1 +
    loop
    drop
;

( R1: 0abcdefg
       ||||||`- 1th bit (g: card is in idle state
       |||||`-- 2th bit (f: erase sequence cleared
       ||||`--- 3th bit (e: illigal command detected
       |||`---- 4th bit (d: crc check error
       ||`----- 5th bit (c: error in the sequence of erase commands
       |`------ 6th bit (b: misaligned addres used in command
       `------- 7th bit (a: command argument outside allowed range
               (8th bit is always zero
)
: sd-wait-notbusy ( -- )
    begin
        h# FF spix
        \ dup \ d# 127 < if exit then \ error returning
        h# ff =
    until
;
: sd-wait-datatoken ( token -- ) 
    \ wait for token
    begin 
        dup h# FF spix    \ t t r 
        \ = if 2drop d# 0 exit then \ token is coming
        \ h# ff <> if drop h# -1 exit then \ error 
        =
    until
    drop
;
: sd-send-command ( cmd -- response )
    sd-wait-notbusy
    d# 6 sd-write-2bytes
    sd-dummy
    h# FF spix
;
: sd-read-block ( buffer block. --  )
    spi_csn off
    sd-wait-notbusy
    \ d# 1 . depth .
    h# 51 spi-wr
    spi-wr16 \ msb
    spi-wr16    
    d# 1 spi-wr \ crc 
    sd-readR1 drop \ response  
    \ d# 2 . depth .
    DATA_TOKEN_CMD17 sd-wait-datatoken
    \ d# 3 . depth .
    d# 512 sd-read-bytes  ( buffer )
    \ d# 4 . depth .
    sd-readR1 drop  \ crc 2 bytes   
    sd-readR1 drop  
    spi_csn on 
; 
: sd-write-block ( block. --  )
    spi_csn off
    sd-wait-notbusy
    \ d# 1 . depth .
    h# 58 spi-wr
    spi-wr16
    spi-wr16   
    d# 1 spi-wr \ crc  
    sd-readR1 drop \ cmd response

    \ sd-readR1 drop \ delay command
    sd-readR1 drop \ delay command
    \ d# 2 . depth .
    DATA_TOKEN_CMD24 spi-wr  \ sd-wait-datatoken
    \ d# 3 . depth .
    buffer d# 512 sd-write-2bytes
    \ d# 4 . depth .
    h# FFFF spi-wr16 \ crc 2 bytes  msb     
    \ d# 41 . depth .    
    ( dataResp:
        xxx0abc1
            010 - Data accepted
            101 - Data rejected due to CRC error
            110 - Data rejected due to write error )    
    sd-readR1 h# 1f and drop \ dataresponse if 5 then ok
    \ d# 5 . depth .
    sd-wait-notbusy
    spi_csn on 
; 
: sd-cold
    \ Step 1.
    spi_csn on
    \ d# 0 . depth .
     d# 10 0do sd-readR1 drop loop
    spi_csn off    
    \ d# 1 . depth . 
    \ Step 2.    
     CMD0 sd-send-command
     drop
    \ != 0x01
    \    SDCARD_Unselect();
    \    return -1;
    \ d# 2 . depth . 
    \ Step 3.         
     CMD8 sd-send-command         
     drop
    \ uint8_t resp[4]
    \ d# 31 . depth . 
    \ buffer d# 4 sd-read-2bytes
    spi-dummy spi-dummy spi-dummy spi-dummy
    \   if(((resp[2] & 0x01) != 1) || (resp[3] != 0xAA)) {
    \ d# 32 . depth . 
    \ Step 4.  And then initiate initialization with ACMD41 with HCS flag (bit 30).
    begin
        CMD55 sd-send-command
        drop         
        ACMD41 sd-send-command        
        d# 0 = 
     until
    \ d# 4 . depth . 
    \ Step 5. After the initialization completed, read OCR register
    ( with CMD58 and check CCS flag bit 30.  When it is set,
    the card is a high-capacity card known as SDHC/SDXC )
    CMD58 sd-send-command
    drop 
    \ buffer d# 4 sd-read-2bytes
    spi-dummy spi-dummy spi-dummy spi-dummy
    \ if((resp[0] & 0xC0) != 0xC0) {
    \ d# 4 . depth . 
    spi_csn on
;

]module 
