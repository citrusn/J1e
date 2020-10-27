( Stars                                      JCB 15:23 11/15/10)

2variable vision
variable frame
128 constant nstars
create stars 1024 allot

: star 2* cells stars + ; ( i -- i*2*2+stars )
: 15.*  m* d2* nip ;

\ >>> math.cos(math.pi / 180) * 32767
\ 32762.009427189474
\ >>> math.sin(math.pi / 180) * 32767
\ 571.8630017304688

[ pi 128e0 f/ fcos 32767e0 f* f>d drop ] constant COSa
[ pi 128e0 f/ fsin 32767e0 f* f>d drop ] constant SINa

: rotate ( i -- ) \ rotate star i
    star dup 2@ ( x y )
    over SINa 15.* over COSa 15.* + >r
    swap COSa 15.* swap SINa 15.* - r>
    rot 2!
;
: rotateall
    d# 128 0do i rotate loop ;

: scatterR
    nstars 0do
        random d# 0 i star 2!
         rotateall
         rotateall
         rotateall
         rotateall
    loop
;
: scatterSpiral
    nstars 0do
        i d# 3 and 1+ d# 8000 *
        d# 0 i star 2!
         rotateall
         rotateall
         rotateall
         rotateall
    loop
    \ stars d# 64 dump
;
: scatter
    nstars 0do
        \ d# 0 random
        d# 0 i sin
        i star 2!
        i random d# 255 and 0do
            dup rotate
        loop drop
    loop
;

: /128  dup 0< h# fe00 and swap d# 7 rshift or ;
: tx    /128 [ 400 ] literal + ;
: ty    /128 [ 256 ] literal + ;

: plot ( i s ) \ plot star i in sprite s
    >r
    dup star @ ( i star_x)
    tx swap ( tx i)
    d# 2 lshift r> ( x y=i*4 spr -- )
    sprite! 
;

( Display list                               JCB 16:10 11/15/10)

create dl 1026 allot

: erasedl \ 
    dl d# 1024 bounds ( a n -- a+n a)
    begin
        d# -1 over ! ( [a]=-1 )
        cell+ 2dup=
    until 2drop
;

: makedl
    erasedl
    
    nstars 0do
        i d# 2 lshift  ( i*4 )
        cells dl + ( i*4*2 + dl )
        \ cell occupied, use one below
        \ dup @ 0< invert if cell+ then
        i swap ! \ в каждый 8 = i
    loop
    \ dl d# 128 dump
    \ 00 00 FF FF FF FF FF FF
    \ 01 00 FF FF FF FF FF FF
;

variable lastsp
: stars-chasebeam
    hide \ hide all the sprites at (800,800)
    d# 0 lastsp !
    d# 512 0do
        begin vga-line@ i = until 
        i cells dl + @ dup 0< if \ -1 в дл
            drop
        else
             lastsp @ 1+ d# 7 and dup lastsp ! \ следующий спрайт
             ( i s )  snap
             plot \ plot star i in sprite s
        then
         i nstars < if i rotate then
        \ sleep1  
    loop ;

: loadcolors
    d# 8 0do
        dup @
        i cells vga_spritec + !
        cell+
    loop
    drop
;
create cpastels
h# 423 ,
h# 243 ,
h# 234 ,
h# 444 ,
h# 324 ,
h# 432 ,
h# 342 ,
h# 244 ,
: pastels cpastels loadcolors ;

create crainbow
h# 400 ,
h# 440 ,
h# 040 ,
h# 044 ,
h# 004 ,
h# 404 ,
h# 444 ,
h# 444 ,
: rainbow crainbow loadcolors ;

: stars-main
    vga-page
    d# 70 loadsprites \ blob.png
    \ d# 16384 0do \ sds
    \    h# 204000. 2/ i s>d d+ flash@
    \    i vga_spritea !  vga_spriteport !
    \ loop

    \ vga_addsprites on \ not wrking sds
    rainbow   
    \ pastels    

    time@ xor seed !
    seed off
     scatterSpiral
    \ scatterR
    \ scatter

    depth if snap drop then
    \ d# 7000000. vision setalarm
    d# 0 frame !    
    makedl

    begin           
        stars-chasebeam     
        \ d# 256 0do i i plot loop
        \ rotateall
        frame @ 1+ frame !       
        istab?  
        next? or
    until
    depth if snap drop then
    frame @ . s"  frames" type cr
    sleep1
    \ pause
;
