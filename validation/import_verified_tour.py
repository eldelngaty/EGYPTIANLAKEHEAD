"""Download only metadata-selected Lakehead scenes. Requires redistribution permission."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json, urllib.request, hashlib, tempfile
from PIL import Image
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
GAME=ROOT/'GAME_GODOT_V5_RUNNING_BASE'
EVIDENCE=ROOT/'tour_evidence'
EVIDENCE.mkdir(exist_ok=True)
CACHE=Path(tempfile.gettempdir())/'sphinx_lakehead_verified_tiles';CACHE.mkdir(exist_ok=True)
META=EVIDENCE
selected=[('agora',13),('corridor',18),('atac',20),('lake',11)]
faces=['front','right','back','left','top','bottom']
entries=[]
for key,page_id in selected:
 data=json.loads((META/f'{key}_metadata.json').read_text())
 (EVIDENCE/f'{key}_metadata.json').write_text(json.dumps(data,indent=2))
 cube=data['cube_map'];level=cube['levels'][0];n=level['nbTiles'];size=level['faceSize']
 dest=GAME/'assets/tour'/key;dest.mkdir(parents=True,exist_ok=True)
 base=f'https://media.circuitcdn.com/lakehead/cube_maps/{cube["id"]}'
 jobs=[(f,c,r) for f in faces for r in range(n) for c in range(n)]
 hashes=[]
 def fetch(job):
  f,c,r=job;name=f'{f}_{c}_{r}.webp';url=f'{base}/{f}/level_1/{name}';local=CACHE/key/name;local.parent.mkdir(exist_ok=True)
  if not local.exists():
   with urllib.request.urlopen(url,timeout=25) as req:local.write_bytes(req.read())
  return {'source':url,'sha256':hashlib.sha256(local.read_bytes()).hexdigest(),'face':f,'column':c,'row':r}
 with ThreadPoolExecutor(max_workers=4) as pool:hashes=list(pool.map(fetch,jobs))
 face_files={}
 arrays={}
 for f in faces:
  im=Image.new('RGB',(size,size))
  for row in range(n):
   for col in range(n):
    tile=Image.open(CACHE/key/f'{f}_{col}_{row}.webp').convert('RGB')
    assert tile.size==(size//n,size//n),(key,f,col,row,tile.size)
    im.paste(tile,(col*tile.width,row*tile.height))
  im.save(dest/f'{f}.png')
  arrays[f]=np.asarray(im).astype(float)
  face_files[f]={'file':f+'.png','sha256':hashlib.sha256((dest/f'{f}.png').read_bytes()).hexdigest()}
 lateral={f'{a}-{b}':float(np.abs(arrays[a][:,-1,:]-arrays[b][:,0,:]).mean()) for a,b in [('front','right'),('right','back'),('back','left'),('left','front')]}
 assert max(lateral.values())<25,(key,lateral)
 entry={'id':key,'name':data['title'],'source_page':'https://virtualtour.lakeheadu.ca/lakehead/lakehead-thunder-bay/'+data['meta']['slug'],'source_api':data['meta']['detail_url'],'page_id':page_id,'image_id':data['panorama_image']['id'],'original_image_url':data['panorama_image']['meta']['download_url'],'cube_map_id':cube['id'],'available_levels':cube['levels'],'source_heading':data['heading'],'source_pitch':data['pitch'],'source_north':data['north'],'face_size':size,'source_level':1,'tiles_per_face':[n,n],'tile_coordinates':'column_row; official viewer tileUrl(face,col,row,level)','texture_folder':'res://assets/tour/'+key,'verified':True,'verification':'Official tour 52 scene list + official page metadata cube_map.id','faces':face_files,'tile_sources':hashes,'lateral_seam_mae':lateral,'godot_mapping':{'front':'-Z','right':'+X','back':'+Z','left':'-X','top':'+Y (u=+X,v=-Z)','bottom':'-Y (u=+X,v=+Z)'},'yaw_degrees':{'agora':-90,'corridor':35,'atac':0,'lake':180}[key]}
 entries.append(entry)
 print(key,'page',page_id,'cube',cube['id'],'seams',lateral)
# The library is a genuine gallery, never mislabeled as a 360 panorama.
library=json.loads((META/'library_metadata.json').read_text())
(EVIDENCE/'library_metadata.json').write_text(json.dumps(library,indent=2))
image=library['gallery_items'][0]['media'][0]['value']
url=image['large']['src'];target=GAME/'assets/tour/library_gallery.jpg'
with urllib.request.urlopen(url,timeout=25) as req:target.write_bytes(req.read())
manifest={'title':'Sphinx Reversal — actual Lakehead tour environments','tour_id':52,'tour_api':'https://lakehead.madewithcircuit.com/api/v2/tours/lakehead-thunder-bay/?format=json','rights':{'basis':'User explicitly confirmed permission includes redistribution in ZIP and GitHub in this conversation','public_license_claimed':False},'scenes':entries,'gallery':{'name':library['title'],'page_id':24,'image_id':image['id'],'source_page':'https://virtualtour.lakeheadu.ca/lakehead/lakehead-thunder-bay/'+library['meta']['slug'],'source_api':library['meta']['detail_url'],'source_image':url,'local_file':'res://assets/tour/library_gallery.jpg','type':'ordinary photograph, not a 360 panorama'},'navigation':'Game-authored hotspot graph between verified camera locations; not a surveyed walking route','photographic_camera_height_m':1.65,'local_proxy_radius_m':3.8,'limitations':['Photographic people and scenery are static; gameplay objects are separate 3D meshes.','Photographic camera stays fixed; only the nearby 3D avatar moves.']}
(GAME/'assets/tour/manifest.json').write_text(json.dumps(manifest,indent=2))
