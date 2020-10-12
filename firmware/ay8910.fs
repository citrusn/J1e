module[ ay8910"
( Структура PSG-формата
  Offset Number of byte Description
  +0 3 Identifier 'PSG'
  +3 1 Marker “End of Text” (1Ah
  +4 1 Version number
  +5 1 Player frequency (for versions 10+
  +6 10 Data

  Data — последовательности пар байтов записи в регистр.
  Первый байт — номер регистра (от 0 до 0x0F,
    второй — значение.
  Вместо номера регистра могут быть специальные маркеры:   
  0xFD — конец композиции.
  0xFF — ожидание 20 мс.
  0xFE — следующий байт показывает сколько раз выждать по 80 мс.
)
( BDIR | BC  | функция         
 ------+-----+----------------    
    0  |  0  |  неактивен         
    0  |  1  |  чтение из ISG     
    1  |  0  |  запись в ISG      
    1  |  1  |  фиксация адреса 
)
(  N регистра |         Hазначение           
    ----------------------------------------- 
    0, 2, 4   | Hижние 8 бит частоты голосов  A,  B,  C;  может  принимать 
              | значения от 0 до 255.        
    1, 3, 5   | Верхние 4 бита частоты голосов A, B, C; может принимать 
              | значения от 0 до 15.         
    6         | Управление  частотой генератора  шума;  может принимать 
              | значения от 0 до 31.         
    7         | Управление    смесителем   и вводом/выводом; может прини- 
              | мать значения от 0 до 255.   
    8, 9, 10  | Управление  амплитудой каналов A, B, C; может принимать 
              | значения от 0 до 16.         
    11        | Hижние   8   бит  управления периодом  пакета; может при- 
              | нимать значения от 0 до 255. 
    12        | Верхние   8  бит  управления периодом  пакета; может при- 
              | нимать значения от 0 до 255. 
    13        | Выбор     формы    волнового пакета; может принимать зна- 
              | чения от 0 до 15.            
    14, 15    | Регистры портов ввода/вывода могут  принимать значения от 
              | 0 до 255.                    
    ----------------------------------------- 
     Основным при работе ISG является регистр 7. Его главное назначение -
     определять  какие  каналы  должны участвовать в образовании  звука
     и определять направление обмена портов ввода/вывода.                                                  
    ----------------------------------------- 
      7   | 6 |  5  | 4 | 3 |  2  | 1 |  0    
    ------+---+-----+---+---+-----+---+------ 
    Порт A|- B|Шум C|- B|- A|Тон C|- B|- A    
    ----------+-------------+---------------- 
    ввод/вывод|кан. для шума| канала для тона 
    ----------------------------------------- 
                                          
     При установлении в регистрах величины  16,  амплитуда  в  канале
     управляется встроенным,  общим для всех трех каналов, генератором
     огибающей. Выбор типа огибающей  и  ее затухание осуществляется 
     в регистре 13.                                
    bit 0 - затухание    bit 1 - изменение    
    bit 2 - нарастание   bit 3 - продолжение  
)
( Выстрел: 
  15 14-bc
  1  1  11111111111101               
  1  0  11111111111101
  10 OUT 65533,6 : OUT 49149,31             
  20 OUT 65533,7 : OUT 49149,7              
  30 OUT 65533,8 : OUT 49149,16             
  40 OUT 65533,9 : OUT 49149,16             
  50 OUT 65533,10: OUT 49149,16             
  60 OUT 65533,12: OUT 49149,18             
  70 OUT 65533,13: OUT 49149,0   
)

: +BC ( -- 256+ )
    d# 256 + 
;
: adr>reg ( n --)
    +BC ay ! 
;
: val>reg ( n --)
    ay ! 
;
: ay-shot
  \ s" shot up" type cr
  d# 6  adr>reg \ частота шума
  d# 31 val>reg
  d# 7  adr>reg \ смеситель 
  d# 7  val>reg \ тон А В C 
  d# 8  adr>reg \ амплитуда А 
  d# 16 val>reg
  d# 9  adr>reg \ амплитуда B
  d# 16 val>reg 
  d# 10 adr>reg \ амплитуда C
  d# 16 val>reg
  d# 12 adr>reg \ период пакета
  d# 18 val>reg
  d# 13 adr>reg \ форма пакета
  d# 0  val>reg \ затухание
  \ s" shot down" type cr
;

variable buf-off

: wait20mc ( -- )
    d# 20000. sleepus 
;
: wait80mc ( c -- )
    drop d# 80000. sleepus 
;
: next-byte ( -- c)
    d# 1 buf-off +!
    buffer buf-off @ + 
    c@l   \ теперь первый младший       
;
: end-buffer 
    buf-off @ d# 512 < 
;
: play-buffer ( )   
    begin
      end-buffer \
    while      
      next-byte \ следующий байт
      dup h# fd = if drop exit else 
      dup h# ff = if drop wait20mc else 
      dup h# fe = if drop next-byte wait80mc else
      adr>reg next-byte val>reg
      then then then
    repeat         
;

: play-psg ( -- )
    d# 176 d# 170 do
      buffer i s>d sd-read-block \ один сектор сд в буфер
      depth if snap then
      \ buffer d# 512 dump
      \ d# 16 buf-off ! \ пропуск заголовка
      d# 0 buf-off !
      play-buffer ( )
      i . cr
      depth if snap then
    loop
;

]module