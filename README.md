# J1e
My extended clone J1 proc

Работающая версия J1 c сайта https://excamera.com/sphinx/fpga-j1.html.
Добавлена работа с SD - картой (чтение и запись секторов) , RS-232 порт (прием-передача),

PS/2 клавиатура (только прием) , генератор AY-3-8910 (на плате один динамик - только моно режим :D ).

Тестовые слова находятся в слове main main.fs. Ethernet на настоящий момент не работает.

Попробую прикрутить модуль Ethernet SPI от Arduino. Проект реализован на китайской 

плате ZEOWAA (именно такой вариант сейчас не продается). Аналогичных много плат.

Отчет:

Family	Cyclone IV E

Device	EP4CE10F17C8

Timing Models	Final

Total logic elements	6,363 / 10,320 ( 62 % )

Total combinational functions	4,886 / 10,320 ( 47 % )

Dedicated logic registers	3,281 / 10,320 ( 32 % )

Total registers	3281

Total pins	112 / 180 ( 62 % )

Total virtual pins	0

Total memory bits	319,488 / 423,936 ( 75 % )

Embedded Multiplier 9-bit elements	2 / 46 ( 4 % )

Total PLLs	1 / 2 ( 50 % )
