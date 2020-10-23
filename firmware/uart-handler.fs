: ok ( --)
  [char] o serout
  [char] k serout 
        bl serout
;
: save-block ( --)
    \ depth if snap then
    uart-char16 \ номер блока     
    d# 512 0do
        \ i .
        uart-char buffer i + c!be
        \ uart-char buffer i 2* + !
    loop
    \ buffer d# 128 dump
    dup . s>d sd-write-block       
    ok
    depth if snap then
;
: save-block1 
  uart-char . 
   d# 512 0do 
      uart-char drop 
   loop
;
: dump-block ( -- )    
    uart-char dup 
    s" sector:" type  . cr
    buffer swap s>d sd-read-block 
    buffer d# 512 dump     
;
: uart-handler ( --)
  depth if snap then
    uart-char 
    dup [char] s = if drop cr save-block else
    dup [char] b = if drop cr s" big chars:" type vga-bigemit-test else
    dup [char] t = if drop cr s" stars:" type stars-main else
    dup [char] h = if drop cr s" shot " type ay-shot else
    dup [char] j = if drop cr s" j1e "  type j1-logo  else
    dup [char] w = if drop cr s" welcome " type  welcome-main  else
    dup [char] p = if drop cr s" play "  type d# 170 play-psg else
    dup [char] l = if drop cr s" dump "  type dump-block else
    dup [char] i = if drop cr s" invaiders " type invaders-main else
    dup [char] r = if drop cr s" reboot"  type  d# 0 >r else  
    drop then then then then then then then then then then
  depth if snap then
  dropall
;
