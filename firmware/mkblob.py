import Image
import math, array, struct

im = Image.new("L", (32,32))
radius = 16
for i in range(32):
  for j in range(32):
    x = abs(i - 16)
    y = abs(j - 16)
    d = math.sqrt(x * x + y * y)
    if d < radius:
        t = 1.0 - (d / radius)
        im.putpixel((i, j), int(255 * (t * t)))
# im.save("blob.png")

filename = "fsm-32.png"
filepic = open(filename + ".spr", "wb")
sa = array.array('B', Image.open(filename).convert("L").tostring())
print (len(sa))
filepic.write(sa)
filepic.close()