\ 33333333 / 115200 = 289, half cycle is 144

: pause144
    d# 0 d# 45
    begin
        1-
        2dup=
    until
    2drop 
;
: serout ( u -- )
    RS232_TXD !
    ( 
      h# 300 or   \ 1 stop bits + 1 parity bit
      2*          \ 0 start bit
      \ Start bit
      begin
        dup RS232_TXD ! 2/
        pause144
        pause144
        dup 0=
      until
      drop 
      pause144 pause144 
      pause144 pause144 )
    \ интервал между началами отправки стартового бита. 
    \ 80 мало. 1 бит 8.6 microSec
    \ 80 - 8X мкС. 100 - 104,3 mS.
    d# 100. sleepus 
;
code serready end-code
: ser? ( -- f)
    RS232_RD_VALID @
;
code serin end-code
: ser-in ( -- c)
    RS232_RD @
;
: uart-char ( -- c )
    begin RS232_RD_VALID @ until
    RS232_RD @
;
: uart-char16 ( -- u )
    begin RS232_RD_VALID @ until
    RS232_RD @ d# 8 lshift 
    begin RS232_RD_VALID @ until
    RS232_RD @ or
;

