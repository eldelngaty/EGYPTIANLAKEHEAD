import * as THREE from '../vendor/three.module.min.js';

// The reversal is a physical wavefront: it leaves the Pharaoh, sweeps over the
// plaza and the Agora facade, and every surface/monument it passes changes world.
// One shared uniform block drives every patched material, so the cost is a few ALU ops.
export const reality={
 uniforms:{
  uOrigin:{value:new THREE.Vector2()},uRadius:{value:999},uFrom:{value:0},uTo:{value:0},
  uSand:{value:new THREE.Color('#e0b27a')},uEdge:{value:new THREE.Color('#ffd27a')},uTime:{value:0}
 },
 waveTime:99,speed:24,
 trigger(x,z,toAncient){
  const u=this.uniforms;u.uOrigin.value.set(x,z);u.uFrom.value=toAncient?0:1;u.uTo.value=toAncient?1:0;u.uRadius.value=0;this.waveTime=0;
  u.uEdge.value.set(toAncient?'#ffcf70':'#7fe6ff');
 },
 reset(){const u=this.uniforms;u.uFrom.value=u.uTo.value=0;u.uRadius.value=999;this.waveTime=99;},
 update(dt,t){this.uniforms.uTime.value=t;this.waveTime+=dt;this.uniforms.uRadius.value=this.waveTime>4?999:this.waveTime*this.speed;},
 // CPU twin of the shader front: lets monuments rise exactly when the wave reaches them.
 target(x,z){const u=this.uniforms,d=Math.hypot(x-u.uOrigin.value.x,z-u.uOrigin.value.y);const f=THREE.MathUtils.smoothstep(u.uRadius.value-d,0,2.5);return u.uFrom.value+(u.uTo.value-u.uFrom.value)*f;}
};

// strength: how far the surface shifts toward sun-baked sandstone in the echo.
// glyphs: draw glowing ritual rings/lines into the floor of the ancient world.
export function patchReality(material,{strength=.8,glyphs=0}={}){
 material.onBeforeCompile=shader=>{
  Object.assign(shader.uniforms,reality.uniforms,{uStrength:{value:strength},uGlyphs:{value:glyphs}});
  shader.vertexShader=shader.vertexShader.replace('#include <common>','#include <common>\nvarying vec3 vRWorld;')
   .replace('#include <project_vertex>','#include <project_vertex>\nvRWorld=(modelMatrix*vec4(transformed,1.0)).xyz;');
  shader.fragmentShader=shader.fragmentShader.replace('#include <common>',`#include <common>
varying vec3 vRWorld;uniform vec2 uOrigin;uniform float uRadius,uFrom,uTo,uStrength,uGlyphs,uTime;uniform vec3 uSand,uEdge;
float rAmt(){float d=distance(vRWorld.xz,uOrigin);return mix(uFrom,uTo,1.-smoothstep(uRadius-2.5,uRadius,d));}`)
   .replace('#include <color_fragment>',`#include <color_fragment>
float rA=rAmt();vec3 baked=mix(vec3(dot(diffuseColor.rgb,vec3(.33))),diffuseColor.rgb,.35)*uSand*1.02;
diffuseColor.rgb=mix(diffuseColor.rgb,baked,rA*uStrength);`)
   .replace('#include <emissivemap_fragment>',`#include <emissivemap_fragment>
{float d=distance(vRWorld.xz,uOrigin);float front=exp(-abs(d-uRadius)*1.1)*step(uRadius,400.);
totalEmissiveRadiance+=uEdge*front*(1.6+uGlyphs);
if(uGlyphs>0.){vec2 p=vRWorld.xz-vec2(0.,1.5);float r=length(p);
float ring=1.-smoothstep(0.,.07,abs(fract(r/3.2)-.5)-.44);
float rays=1.-smoothstep(0.,.05,abs(fract(atan(p.y,p.x)/6.2832*24.)-.5)-.47);
float glow=(ring+rays*step(3.,r)*.6)*(.55+.45*sin(uTime*1.7-r*.5));
totalEmissiveRadiance+=vec3(1.,.72,.32)*glow*rA*uGlyphs*.55;}}`);
 };
 material.customProgramCacheKey=()=>'reality-'+glyphs;
 return material;
}

// Gradient sky dome with a sun that becomes the Eye of Ra in the echo.
export function createSky(scene){
 const mat=new THREE.ShaderMaterial({side:THREE.BackSide,depthWrite:false,fog:false,uniforms:{uMix:{value:0},uTime:{value:0}},
  vertexShader:'varying vec3 vDir;void main(){vDir=normalize(position);vec4 p=projectionMatrix*modelViewMatrix*vec4(position,1.);gl_Position=p.xyww;}',
  fragmentShader:`varying vec3 vDir;uniform float uMix,uTime;
void main(){float h=clamp(vDir.y,-.2,1.);
vec3 mTop=vec3(.24,.47,.80),mHor=vec3(.78,.87,.95),aTop=vec3(.13,.07,.24),aHor=vec3(.98,.55,.30);
vec3 col=mix(mix(mHor,mTop,pow(max(h,0.),.6)),mix(aHor,aTop,pow(max(h,0.),.45)),uMix);
vec3 sd=normalize(vec3(-.35,.32+.08*uMix,-1.));float s=max(dot(vDir,sd),0.);
col+=mix(vec3(1.,.95,.82),vec3(1.,.62,.25),uMix)*(pow(s,900.)*2.+pow(s,24.)*(.18+.5*uMix));
float stars=step(.9985,fract(sin(dot(floor(vDir*180.),vec3(12.9,78.2,37.7)))*43758.5))*uMix*smoothstep(.15,.6,h);
col+=vec3(stars)*(.6+.4*sin(uTime*3.+vDir.x*90.));
gl_FragColor=vec4(col,1.);}`});
 const dome=new THREE.Mesh(new THREE.SphereGeometry(160,32,16),mat);dome.frustumCulled=false;dome.renderOrder=-10;scene.add(dome);
 return {dome,update(mix,t,camera){mat.uniforms.uMix.value=mix;mat.uniforms.uTime.value=t;dome.position.copy(camera.position);}};
}

// The visible shell of the wave: a fresnel bubble expanding from the Pharaoh.
export function createShockwave(scene){
 const mat=new THREE.ShaderMaterial({transparent:true,depthWrite:false,blending:THREE.AdditiveBlending,side:THREE.DoubleSide,
  uniforms:{uColor:{value:new THREE.Color('#ffcf70')},uFade:{value:0}},
  vertexShader:'varying vec3 vN,vV;void main(){vec4 w=modelViewMatrix*vec4(position,1.);vN=normalize(normalMatrix*normal);vV=normalize(-w.xyz);gl_Position=projectionMatrix*w;}',
  fragmentShader:'varying vec3 vN,vV;uniform vec3 uColor;uniform float uFade;void main(){float f=pow(1.-abs(dot(vN,vV)),3.);gl_FragColor=vec4(uColor*f*uFade*1.4,1.);}'});
 const shell=new THREE.Mesh(new THREE.SphereGeometry(1,40,20,0,Math.PI*2,0,Math.PI/2),mat);shell.visible=false;shell.frustumCulled=false;scene.add(shell);
 return {update(){const w=reality.waveTime;shell.visible=w<1.9;if(!shell.visible)return;const r=Math.max(.01,w*reality.speed);shell.scale.set(r,r*.42,r);shell.position.set(reality.uniforms.uOrigin.value.x,0,reality.uniforms.uOrigin.value.y);mat.uniforms.uColor.value.copy(reality.uniforms.uEdge.value);mat.uniforms.uFade.value=Math.max(0,1-w/1.9)*Math.min(1,w*8);}};
}

// Procedural hieroglyphs: ankh, eye, reeds, water, bird, sun disc. Vector strokes only.
export function drawGlyph(g,type,x,y,s){
 g.save();g.translate(x,y);g.scale(s,s);g.beginPath();
 switch(type%7){
  case 0: g.ellipse(0,-.55,.22,.3,0,0,Math.PI*2);g.moveTo(0,-.25);g.lineTo(0,.8);g.moveTo(-.38,0);g.lineTo(.38,0);break; // ankh
  case 1: g.moveTo(-.6,0);g.quadraticCurveTo(0,-.55,.6,0);g.quadraticCurveTo(0,.4,-.6,0);g.moveTo(.12,0);g.arc(0,0,.14,0,Math.PI*2);g.moveTo(0,.25);g.lineTo(-.1,.75);g.moveTo(.25,.2);g.quadraticCurveTo(.6,.4,.45,.75);break; // eye
  case 2: for(const dx of [-.35,0,.35]){g.moveTo(dx,.8);g.lineTo(dx,-.5);g.moveTo(dx,-.5);g.quadraticCurveTo(dx+.25,-.75,dx+.15,-.3);}break; // reeds
  case 3: for(const dy of [-.35,0,.35]){g.moveTo(-.65,dy);for(let i=0;i<6;i++)g.lineTo(-.65+(i+.5)*.22,dy+(i%2?-.12:.12));g.lineTo(.65,dy);}break; // water
  case 4: g.moveTo(-.5,.6);g.quadraticCurveTo(-.4,-.1,.1,-.2);g.lineTo(.3,-.55);g.lineTo(.55,-.45);g.lineTo(.35,-.2);g.quadraticCurveTo(.4,.3,-.1,.4);g.moveTo(0,.4);g.lineTo(-.05,.8);g.moveTo(.15,.38);g.lineTo(.2,.8);break; // bird
  case 5: g.arc(0,0,.42,0,Math.PI*2);g.moveTo(.12,0);g.arc(0,0,.12,0,Math.PI*2);g.moveTo(-.6,.65);g.lineTo(.6,.65);break; // sun disc
  default: g.moveTo(-.4,.8);g.lineTo(-.4,-.4);g.quadraticCurveTo(0,-.9,.4,-.4);g.lineTo(.4,.8);g.moveTo(-.4,.1);g.lineTo(.4,.1);break; // shrine
 }
 g.stroke();g.restore();
}
export function glyphTexture(width,height,{cols=16,rows=2,color='#ffd98a',glow='#ff9d2e',seed=3,back=null}={}){
 const c=document.createElement('canvas');c.width=width;c.height=height;const g=c.getContext('2d');
 if(back){g.fillStyle=back;g.fillRect(0,0,width,height);}
 g.strokeStyle=color;g.lineCap='round';g.lineJoin='round';g.shadowColor=glow;g.shadowBlur=18;
 const cw=width/cols,ch=height/rows,s=Math.min(cw,ch)*.36;
 g.lineWidth=.11;
 for(let r=0;r<rows;r++)for(let i=0;i<cols;i++)drawGlyph(g,(i*3+r*5+seed)%7,cw*(i+.5),ch*(r+.5),s);
 g.shadowBlur=0;g.lineWidth=3;g.strokeStyle=color;g.globalAlpha=.7;
 for(let r=0;r<=rows;r++){g.beginPath();g.moveTo(0,r*ch+(r===0?2:r===rows?-2:0));g.lineTo(width,r*ch+(r===0?2:r===rows?-2:0));g.stroke();}
 const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=4;return t;
}
