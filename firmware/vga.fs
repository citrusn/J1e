( VGA: VGA           JCB 13:14 08/24/10)
module[ vga"

variable cursory \ ptr to start of line in video memory
variable cursorx \ offset to char

64 constant width
50 constant wrapcolumn

: vga-at-xy ( u1 u2 )
    cursory !
    cursorx !
;

: home  d# 0 vga_scroll ! d# 0 d# 0 vga-at-xy ;

: vga-line ( -- a ) \ address of current line
    cursory @ vga_scroll @ + d# 31 and d# 6 lshift 
    h# 8000 or
;

: vga-erase ( a u -- )
    bounds begin
        2dupxor
    while
        h# 00 over ! 1+
    repeat 2drop
;

: vga-page
    home vga-line d# 2048 vga-erase
    hide
;

: down1
    cursory @ d# 31 <> if
        d# 1 cursory +!
    else
        false if
            d# 1 vga_scroll +!
            vga-line width vga-erase
        else
            home
        then
    then
;

: vga-emit ( c -- )    
    dup d# 13 = if
        drop d# 0 cursorx !
    else
        dup d# 10 = if
            drop down1
        else
            \ d# -32 +
            vga-line cursorx @ + !
            d# 1 cursorx +!
            cursorx @ wrapcolumn = if
                d# 0 cursorx !
                down1
            then
        then
    then
;

: chars-table-cold
    h# f000 d# 10 d# 4 sd>memory \ знакогенератор  
;

: vga-cold
    \ h# f800 h# f000 do \ sds
    \    d# 0 i !
    \ loop

    vga-page

    \ pic: Copy 2048 bytes from 180000 to 8000
    \ chr: Copy 2048 bytes from 180800 to f000
    \ h# 180000. h# 8000 flash>ram \ sds
    \ h# 180800. h# f000 flash>ram \ sds chars fonts 8*8
    chars-table-cold

    \ ['] vga-emit 'emit !
;

create glyph 8 allot
: wide1 ( c -- )
    swab
    d# 8 0do
        dup 0<
        if d# 15 else sp then
        \ if [char] * else [char] . then
        vga-emit
        2*
    loop drop
    \ depth if snap then   
;

: table-chars-read ( n -- )
    buffer swap ( buffer n  )
    s>d \ 2dup ( buffer block. block. )
    \ s" sd-read " type d. s" block " type ( buffer block. )
    sd-read-block  ( buffer block. )
    \ buffer d# 512 dump
    \ depth if snap then   
;

: vga-bigemit ( c -- )  
dup serout  
    dup d# 13 = if
        drop d# 0 cursorx !
    else
        dup d# 10 = if
            drop d# 8 0do down1 loop
        else
            \ sp - d# 8 *  s>d   \ отнять код пробела            
            d# 8 * dup ( addr addr -- ) \ адрес в знакогенераторе
            \ расчет номера сектора карты в память начиная с 10
            \ исходя из 512 байт на сектор
            d# 9 rshift d# 10 + table-chars-read ( addr )
            d# 511 and \ адрес  в пределах блока 512 байт ( offset)
            
            \ h# 180800. d+ d2/  \ 16 бит шина данных 
            buffer +             \ 
            d# 4 0do
                \ 2dup flash@ swab
                dup @ swab
                i cells glyph + !
                2+
            loop drop
            \ glyph d# 8 dump
            d# 7 0do
                i glyph + c@ wide1
                d# -8 cursorx +! down1
            loop
            d# 7 glyph + c@ wide1

            d# -7 cursory +!
        then
    then
    \ depth if snap then   
;

: fill-screen (  --  ) \ заполнение экранной памяти
    h# 800 0do \ число символов
       i h# 8000 i + ! \ адрес экранной памяти
    loop
;

: fill-chars (  --  ) \ заполнение знакогенератора
    h# f800 h# f000 do \ число символов
       d# 0 i ! \ очистка по адресу экранной памяти
    loop
    
    \ h# f000 d# 2047 d# 0 fill
    h# 256 0do \ число символов
        i d# 8 i * h# f000 + ! \ адрес знакогенератора
    loop
;

(  \ переносит данные из программной 
    \ 16 битной памяти в 8 битную 
 buffer d# 15 d# 1 sd>memory \ знакогенератор        
    h# f000
    d# 256 0do ( addr  
        buffer i cells + @ 2dup i buffer - . dup . cr ( addr u addr u 
        d# 8 rshift swap ! ( addr u 
         swap 1+  ( u addr+1  
        tuck ( addr+1 u addr+1 
        ! 1+ ( addr+1  
    loop 
    drop
)

]module 

