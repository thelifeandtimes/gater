'use strict';
window.GaterCommunity = (() => {
  const defaults = {background:'#0c0c0d',surface:'#141416',text:'#ecece8',muted:'#8e8e87',accent:'#c5ccd6',secondary:'#7d9a7a',tertiary:'#c5ccd6',raised:'#1c1c1f',error:'#c45c4a',selection:'#2a2a2e',link:'#c5ccd6',border:'#2a2a2e',fontDisplay:'Newsreader, Georgia, serif',fontBody:'IBM Plex Sans, system-ui, sans-serif',fontMono:'IBM Plex Mono, monospace',spacing:'comfortable',rounding:'soft',footer:''};
  const vars={background:'--paper',surface:'--surface',text:'--ink',muted:'--muted',accent:'--green',secondary:'--secondary',tertiary:'--tertiary',raised:'--raised',error:'--danger',selection:'--selection',link:'--link',border:'--line'};
  const hex=v=>typeof v==='string' && /^#[\da-f]{6}$/i.test(v);
  const family=v=>typeof v==='string' && /^[a-z0-9 ,\-]{1,160}$/i.test(v);
  const mix=(a,b,t)=>'#'+[1,3,5].map(i=>Math.round(parseInt(a.slice(i,i+2),16)*(1-t)+parseInt(b.slice(i,i+2),16)*t).toString(16).padStart(2,'0')).join('');
  const luminance=c=>[1,3,5].map(i=>parseInt(c.slice(i,i+2),16)/255).map(v=>v<=.04045?v/12.92:((v+.055)/1.055)**2.4).reduce((a,v,i)=>a+v*[.2126,.7152,.0722][i],0);
  const validID=id=>/^[a-z][a-z0-9-]{0,63}$/.test(id||'');
  function selected() { const part=location.pathname.split('/')[2]; if(part&&!['claim','config'].includes(part)&&validID(part)) return part; const hint=new URLSearchParams(location.search).get('collection'); return validID(hint)?hint:null; }
  function fromProfile(profile) {
    const c=profile?.colors || profile;
    if(!c || !hex(c.background) || !hex(c.foreground || c.text)) throw Error('A palette needs six-digit background and foreground (or text) colors.');
    const bg=c.background,fg=c.foreground||c.text,accent=c.accent||c.primary||c.blue||fg;
    const b={background:bg,text:fg,accent, surface:c.dark_background||c.surface||mix(bg,fg,.035), raised:c.lighter_background||c.raised||mix(bg,fg,.07),muted:c.muted||c.dark_foreground||mix(bg,fg,.65),secondary:c.secondary||c.cyan||accent,tertiary:c.tertiary||c.green||accent,error:c.error||c.red||defaults.error,selection:c.selection||mix(bg,accent,.22),link:c.link||c.blue||accent,border:mix(bg,fg,.18)};
    const safe=Object.fromEntries(Object.entries(c).filter(([k,v])=>/^[a-z][a-z0-9_]{0,40}$/i.test(k)&&hex(v)));
    b.palette=JSON.stringify(safe);
    if(family(profile.font)) for(const key of ['fontDisplay','fontBody','fontMono']) b[key]=profile.font+', monospace';
    return {...b,themeMode:'custom'};
  }
  let themeCache;
  const xProfiles=new Map(), fonts=new Map();
  function safeImage(url) { try {const u=new URL(url);return ['https:','http:'].includes(u.protocol)&&!u.username&&!u.password?u.href:null;}catch{return null;} }
  async function image(el,url,alt) {
    if(!el)return; el.dataset.requestedImage=url||''; el.alt=alt; el.referrerPolicy='no-referrer'; el.loading='lazy';
    let value=safeImage(url); const x=value&&/^https:\/\/(?:www\.)?(?:x|twitter)\.com\/[\w]{1,15}\/(?:photo|header_photo)\/?(?:\?.*)?$/.test(value);
    if(x){
      try {
        const match=new URL(url).pathname.match(/^\/([\w]{1,15})\/(photo|header_photo)\/?$/);
        if(match){const handle=match[1];if(!xProfiles.has(handle))xProfiles.set(handle,fetch('https://api.fxtwitter.com/'+encodeURIComponent(handle),{credentials:'omit',referrerPolicy:'no-referrer',signal:AbortSignal.timeout(8000)}).then(r=>{if(!r.ok)throw Error('Profile unavailable');return r.json();}));const profile=(await xProfiles.get(handle)).user;value=profile?.[match[2]==='photo'?'avatar_url':'banner_url'];if(!value||new URL(value).hostname!=='pbs.twimg.com')value=null;else if(match[2]==='photo')value=value.replace(/_(normal|bigger|200x200)(?=\.)/,'_400x400');}
      }catch{value=null;}
    }
    if(el.dataset.requestedImage!==(url||''))return;
    el.hidden=!value;
    if(x&&!value)el.dispatchEvent(new CustomEvent('image-unavailable',{bubbles:true}));
    if(value){el.src=value;el.onerror=()=>{el.hidden=true;el.dispatchEvent(new CustomEvent('image-unavailable',{bubbles:true}));};}else el.removeAttribute('src');
  }
  function themeMode(brand={}) {
    if(['host','custom'].includes(brand.themeMode)) return brand.themeMode;
    // Legacy saved default colors should inherit; retain deliberate palettes.
    const old={background:'#f6f5ee',surface:'#ffffff',text:'#202c23',muted:'#63705f',accent:'#27633d'};
    return brand.palette || Object.entries(old).some(([k,v])=>brand[k]&&brand[k]!==v) ? 'custom' : 'host';
  }
  const fontOverride=(brand,key)=>!brand.themeMode&&brand[key]===defaults[key]?'':brand[key]||'';
  function resolved(brand={}) {
    if(themeMode(brand)==='host') {
      const b={...defaults,...brand,...(themeCache||defaults),themeMode:'host'};
      for(const k of ['fontDisplay','fontBody','fontMono','fontDisplayURL','fontBodyURL','fontMonoURL','spacing','rounding','footer']) if(k.startsWith('font')?fontOverride(brand,k):brand[k])b[k]=brand[k];
      return b;
    }
    let base={...defaults};
    if(hex(brand.background)&&hex(brand.text))base={...base,...fromProfile(brand)};
    if(brand.palette){try{base={...base,...fromProfile(JSON.parse(brand.palette))};}catch{}}
    return {...base,...brand};
  }
  function apply(brand={},root=document.documentElement) {
    const b=resolved(brand);
    for(const [key,variable] of Object.entries(vars))root.style.setProperty(variable,hex(b[key])?b[key]:defaults[key]);
    root.style.setProperty('--on-accent',luminance(hex(b.accent)?b.accent:defaults.accent)>.179?'#000000':'#ffffff');
    root.style.colorScheme=luminance(hex(b.background)?b.background:defaults.background)>.179?'light':'dark';
    for(const key of ['fontDisplay','fontBody','fontMono'])root.style.setProperty('--'+key.replace(/[A-Z]/g,m=>'-'+m.toLowerCase()),family(b[key])?b[key]:defaults[key]);
    for(const key of ['fontDisplay','fontBody','fontMono']) {
      const url=safeImage(b[key+'URL']); if(!url)continue;
      if(!fonts.has(url)) { const name='GaterFont'+fonts.size; const face=new FontFace(name,'url('+JSON.stringify(url)+')',{display:'swap'}); document.fonts.add(face); fonts.set(url,name); face.load().catch(()=>{}); }
      root.style.setProperty('--'+key.replace(/[A-Z]/g,m=>'-'+m.toLowerCase()),fonts.get(url)+', '+(family(b[key])?b[key]:defaults[key]));
    }
    root.style.setProperty('--space',({compact:'.8',comfortable:'1',roomy:'1.2'})[b.spacing]||'1');
    root.style.setProperty('--radius',({square:'0px',soft:'12px',round:'24px'})[b.rounding]||'12px');
    for(let i=root.style.length-1;i>=0;i--){const key=root.style[i];if(key.startsWith('--omarchy-'))root.style.removeProperty(key);}
    try {for(const [k,v] of Object.entries(JSON.parse(b.palette||'{}')))if(/^[a-z][a-z0-9_]{0,40}$/i.test(k)&&hex(v))root.style.setProperty('--omarchy-'+k.replaceAll('_','-'),v);}catch{}
  }
  async function shipTheme(){
    const response=await fetch('/gater/appearance',{credentials:'same-origin'});
    if(!response.ok)throw Error('Host theme is unavailable.');
    const data=await response.json(), synced=Object.keys(data).length>0;
    const status=document.getElementById('theme-status');
    if(status)status.textContent=synced?'Following this host’s synced appearance in %settings.':'No synced appearance profile is installed on this host. Using the Omart / Tend default; a profile synced to another ship is not available through EAuth.';
    themeCache=synced?fromProfile(data):{...defaults,themeMode:'custom'};
    return themeCache;
  }
  async function followHost(brand={},root=document.documentElement){
    const refresh=async()=>{try{await shipTheme();apply({...brand,themeMode:'host'},root);document.dispatchEvent(new Event('gater-theme'));}catch{}};
    apply({...brand,themeMode:'host'},root); await refresh();
    setInterval(()=>{if(!document.hidden)refresh();},30000);
    document.addEventListener('visibilitychange',()=>{if(!document.hidden)refresh();});
  }
  async function load(claim=false) {
    const id=selected();if(!id){followHost();return;}
    const response=await fetch(`/gater/${encodeURIComponent(id)}/info`,{credentials:'same-origin'});
    if(!response.ok)throw Error('This community is no longer available.');
    const c=await response.json(),b=c.brand||{};if(themeMode(b)==='host') await followHost(b);else apply(b);document.title=`${c.name} · ${claim?'Your membership':'Join the community'}`;
    const brand=document.querySelector('header .brand');brand.textContent=c.name;brand.href=`/gater/${encodeURIComponent(id)}`;
    document.getElementById('community-name').textContent=c.name;
    const title=claim?b.claimTitle||b.title:b.title,description=claim?b.claimSubtitle||b.subtitle:b.subtitle;
    if(title)document.getElementById('community-title').textContent=title;
    if(description)document.getElementById('community-subtitle').textContent=description;
    document.getElementById('community-footer').textContent=b.footer||'';
    image(document.getElementById('header-image'),b.header,'');image(document.getElementById('avatar-image'),b.avatar,`${c.name} avatar`);
  }
  return {defaults,resolved,themeMode,fontOverride,selected,image,apply,load,fromProfile,shipTheme,followHost,safeImage};
})();
