0 [IF]
    h# 1f80 org
    \ the RAM Bootloader copies 2000-3f80 to 0-1f80, then branches to zero
    : bootloader
        h# 1f80 h# 0
        begin
            2dupxor
        while
            dup h# 2000 + @
            over !
            d# 2 +
        repeat

        begin dsp h# ff and while drop repeat
        d# 0 >r
    ;
[ELSE]
    h# 3f80 org \ 1fc0 8128 - адрес начало загрузчика. 
                \ 8192 размер памяти всего
    \ the Flash Bootloader copies 0x190000 to 0-3f80, then branches to zero
    : bootloader
        h# c flash_a_hi !
        h# 0 begin
        (
            dup h# 8000 + flash_a !
            d# 0 flash_oe_n !
            flash_d @
            d# 1 flash_oe_n !
        )
            
            over dup + !
            d# 1 +
            dup h# 1fc0 =
        until

        begin dsp h# ff and while drop repeat
        d# 0 >r
    ;
[THEN]