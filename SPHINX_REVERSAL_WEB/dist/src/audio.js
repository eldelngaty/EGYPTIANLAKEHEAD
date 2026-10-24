// Original, procedural Web Audio score. All sound is synthesized in the browser.
export function createAudio(){
 let ctx,master,ambient,muted=false,ancient=false,timer;
 const init=()=>{if(ctx){if(ctx.state==='suspended')ctx.resume();return;}try{
  ctx=new(window.AudioContext||window.webkitAudioContext)();master=ctx.createGain();master.gain.value=.45;master.connect(ctx.destination);
  ambient=ctx.createGain();ambient.gain.value=.025;ambient.connect(master);
  for(const freq of [73.42,110,146.83]){const o=ctx.createOscillator();o.type='sine';o.frequency.value=freq;o.connect(ambient);o.start();}
  let beat=0;timer=setInterval(()=>{if(!ctx||ctx.state!=='running'||document.hidden)return;const scale=ancient?[293.66,349.23,440,466.16,587.33]:[293.66,440,523.25,587.33,659.25];tone(scale[[0,2,1,4,3,2,0,1][beat++%8]],1.8,'sine',.025)},2100);
 }catch{ctx=null}};
 function tone(freq,duration=.3,type='sine',volume=.16,delay=0,end=freq*.997){if(!ctx)return;const t=ctx.currentTime+delay,o=ctx.createOscillator(),g=ctx.createGain();o.type=type;o.frequency.setValueAtTime(freq,t);o.frequency.exponentialRampToValueAtTime(end,t+duration);g.gain.setValueAtTime(.001,t);g.gain.exponentialRampToValueAtTime(volume,t+.025);g.gain.exponentialRampToValueAtTime(.001,t+duration);o.connect(g);g.connect(master);o.start(t);o.stop(t+duration+.05);}
 function reverse(isAncient){init();ancient=isAncient;if(!ctx)return;const t=ctx.currentTime,n=Math.floor(ctx.sampleRate*.9),b=ctx.createBuffer(1,n,ctx.sampleRate),d=b.getChannelData(0);for(let i=0;i<n;i++)d[i]=(Math.random()*2-1)*Math.sin(i/n*Math.PI);const s=ctx.createBufferSource(),f=ctx.createBiquadFilter(),g=ctx.createGain();s.buffer=b;f.type='bandpass';f.frequency.setValueAtTime(isAncient?200:2600,t);f.frequency.exponentialRampToValueAtTime(isAncient?2600:180,t+.8);f.Q.value=.6;g.gain.value=.16;s.connect(f);f.connect(g);g.connect(master);s.start();for(let i=0;i<4;i++)tone([146.83,220,293.66,440][i],.9,'sine',.1,i*.075);}
 return {init,reverse,collect:()=>{init();[587.33,880,1174.66].forEach((f,i)=>tone(f,.65,'sine',.13,i*.09))},offer:n=>tone(293.66*[1,1.5,2][n%3],.45,'triangle',.12),error:()=>tone(110,.25,'triangle',.09,0,75),win:()=>{for(let i=0;i<8;i++)tone([293.66,369.99,440,587.33,739.99,880,1174.66,1479.98][i],2.5,'sine',.12,i*.16)},toggle:()=>{init();muted=!muted;if(master)master.gain.setTargetAtTime(muted?0:.45,ctx.currentTime,.1);return muted},setAncient:v=>{ancient=v},suspend:()=>ctx?.suspend(),resume:()=>{if(ctx)ctx.resume()}};
}
