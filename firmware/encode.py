# -*- coding: cp1251 -*-
import struct
import sys

from array import array
from PIL import Image, ImageDraw

def getch(im, x, y):
    return tuple(tuple((int(0 != im.getpixel((x + j, y + i)))) for j in range(8)) for i in range(8))

def main(filename):
    sm = Image.open(filename).convert("L")
    # длина строки 8*64 символа= 512 пиксе.
    # длина видимой области 400 пикс / 8= 50 символов
    im = Image.new("L", (512, 256))    
    im.paste(sm, (0, 0))

    charset = {}
    picture = []
    print('width:', im.size[0], 'height:', im.size[1])
    filepic = open(filename + ".pic", "wb")
    for y in range(8*0, 8*32, 8):
        for x in range(0, im.size[0], 8):
            glyph = getch(im, x, y)
            if not glyph in charset:
                charset[glyph] = 0 + len(charset)  # 96 + sds            
            filepic.write(struct.pack('>b', charset[glyph]))
            picture.append(charset[glyph])
    print('Size of picture:', len(picture))
    filepic.close()
    # open(filename + ".pic", "w").write(array('B', picture).tostring()) # неправильно работает 

    cd = array('B', [0] * 8 * len(charset))
    print('Length charset:', len(charset))
    for d, i in charset.items():
        # i -= 96 # sds
        for y in range(8):
            cd[8 * i + y] = sum([(d[y][x] << (7 - x)) for x in range(8)])
    open(filename + ".chr", "wb").write(cd)

# main(sys.argv[1])

def pngstr(filename):    
    # sa = array('B', Image.open(filename).convert("L").tostring())
    # return struct.pack('>1024H', *sa.tolist()) # зачем непонятно
    sa = Image.open(filename).convert("L").tobytes()
    return sa
    
def loadsprites(filenames):
    data = b"".join([pngstr(f) for f in filenames])
    print("Loading %d bytes" % len(data))
    return array('B', data)

def createSpriteFile():
    filename = "numbers"
    #filename = "blobs"
    filename = "invs"

    filepic = open(filename + ".spr", "wb")

    spr = ["%d.png" % (i/2) for i in range(16)]
    # spr = ["blob.png"] * 16
    spr = ["fsm-32.png", "pop2.png"]*6+["bomb3.png", "pop.png", "shot2.png", "pop2.png"]

    print (filepic.name)
    data = loadsprites(spr)
    filepic.write(data)
    filepic.close()

createSpriteFile()