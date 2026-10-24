from PIL import Image, ImageDraw
from pathlib import Path
import random
r=random.Random(601)
out=Path(__file__).resolve().parents[1] / 'GAME_GODOT_V5_RUNNING_BASE' / 'assets'
for name in ['brick','concrete','paving']:
 im=Image.new('RGB',(512,512)); p=im.load()
 base={'brick':(139,111,95),'concrete':(173,177,166),'paving':(177,174,158)}[name]
 for y in range(512):
  for x in range(512):
   n=r.randint(-10,10)
   p[x,y]=tuple(max(0,min(255,c+n)) for c in base)
 d=ImageDraw.Draw(im)
 if name=='brick':
  for y in range(0,512,32):
   d.rectangle((0,y,511,y+2),fill=(101,101,89))
   for x in range(-64 if y//32%2 else 0,512,128):
    d.rectangle((x,y,x+3,y+31),fill=(101,101,89))
    d.line((x+4,y+4,x+124,y+4),fill=(165,137,115),width=1)
 else:
  step=128 if name=='paving' else 256
  for a in range(0,512,step):
   d.line((a,0,a,511),fill=(124,133,125),width=2)
   d.line((0,a,511,a),fill=(124,133,125),width=2)
 im.save(out/f'art_{name}.png')
