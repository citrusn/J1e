# -*- coding: cp1251 -*-
import sys, struct
import Image
import ImageDraw
from array import array

def getch(im, x, y):
    return tuple(tuple((int(0 != im.getpixel((x + j, y + i)))) for j in range(8)) for i in range(8))
    
def main(filename):
    sm = Image.open(filename).convert("L")
    im = Image.new("L", (512, 256)) # длина строки 8*64 символа= 512 пиксе. 
                                    # длина видимой области 400 пикс / 8= 50 символов
    im.paste(sm, (0,0))
    
    charset = {}
    picture = []
    i = 0 
    print im.size[0], im.size[1]
    filepic = open(filename + ".pic", "wb")
    for y in range(8*0, 8*32, 8):
        # i=0 
        for x in range(0, im.size[0], 8):
            glyph = getch(im, x, y)            
            if not glyph in charset:
                charset[glyph] = 0 + len(charset) # 96 + sds
            #print i, '-', charset[glyph], 
            #filepic.write( str(i) +':'+ str(charset[glyph])+';\n' )
            filepic.write( struct.pack('>b', charset[glyph] ))
            i = i + 1
            picture.append(charset[glyph])
        #print 
    print len(picture)
    filepic.close()
    #open(filename + ".pic", "w").write(array('B', picture).tostring()) # не работает правильно
    cd = array('B', [0] * 8 * len(charset))
    print 'len charset =' , len(charset)
    for d,i in charset.items():
        # i -= 96 # sds
        for y in range(8):
            cd[8 * i + y] = sum([(d[y][x] << (7 - x)) for x in range(8)])
    open(filename + ".chr", "w").write(cd.tostring())

# main(sys.argv[1])

def pngstr(filename):
    import Image
    #sa = array('B', Image.open(filename).convert("L").tostring())
    sa = Image.open(filename).convert("L").tostring()
    return sa
    # return struct.pack('>1024H', *sa.tolist()) # зачем непонятно

def loadsprites( filenames):
    data = "".join([pngstr(f) for f in filenames])
    print "Loading %d bytes" % len(data)
    return array('B', data)


filename = "numbers"
filename = "blobs"
filename = "invs"
filepic = open(filename + ".spr", "wb")

spr = ["%d.png" % (i/2) for i in range(16)]
spr = ["blob.png"] * 16
spr = ["fsm-32.png", "pop.png"] * 6 + ["bomb2.png", "pop.png", "shot.png", "pop.png"]
#print spr
data = loadsprites(spr)
filepic.write(data)
filepic.close()