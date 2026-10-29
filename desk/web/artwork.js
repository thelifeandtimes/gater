'use strict';
// Display data never enters Gall. Only authenticated holdings can be queued.
const GaterArtwork = (() => {
  const KEY = 'gater.artwork.v1', TTL = 86400000, LIMIT = 262144, MAX_ROWS = 128;
  const RPC = {'1':'https://ethereum-rpc.publicnode.com', '8453':'https://base-rpc.publicnode.com'};
  function resource(value) {
    if (typeof value !== 'string' || value.length > 2048 || /[\x00-\x20]/.test(value)) throw Error('Invalid artwork URL');
    if (value.startsWith('ipfs://')) value = 'https://ipfs.io/ipfs/' + value.slice(7).replace(/^ipfs\//, '');
    if (value.startsWith('ar://')) value = 'https://arweave.net/' + value.slice(5);
    const u = new URL(value), h = u.hostname.toLowerCase();
    if (u.protocol !== 'https:' || u.username || u.password || (u.port && u.port !== '443') ||
        !h.includes('.') || h.endsWith('.local') || h.endsWith('.localhost') || h.endsWith('.internal') ||
        h.startsWith('[') || /^\d+(\.\d+){3}$/.test(h)) throw Error('Public HTTPS artwork required');
    return u.href;
  }
  function template(value, id) {
    if (!/^(0|[1-9]\d*)$/.test(id) || BigInt(id) >= 2n**256n || !value.includes('{id}')) throw Error('Invalid artwork pattern');
    return resource(value.replaceAll('{id}', id));
  }
  function abiString(raw) {
    if (typeof raw !== 'string' || !/^0x(?:[a-f\d]{2})+$/i.test(raw) || raw.length > LIMIT*2+130 || raw.length < 130) throw Error('Invalid tokenURI');
    if (BigInt('0x'+raw.slice(2,66)) !== 32n) throw Error('Invalid tokenURI offset');
    const size = BigInt('0x'+raw.slice(66,130));
    if (size > BigInt(LIMIT) || 130+Number(size)*2 > raw.length) throw Error('Invalid tokenURI size');
    return new TextDecoder('utf-8',{fatal:true}).decode(Uint8Array.from(raw.slice(130,130+Number(size)*2).match(/../g)||[], b=>parseInt(b,16)));
  }
  function identity(c, t) {
    if (!RPC[c.chain] || !/^0x[a-f\d]{40}$/i.test(c.contract) || !/^(0|[1-9]\d*)$/.test(t.id) || BigInt(t.id)>=2n**256n) throw Error('Invalid NFT');
    return `${c.chain}:${c.contract.toLowerCase()}:${t.id}`;
  }
  function create(options={}) {
    const fetcher = options.fetch || fetch, now = options.now || Date.now;
    let storage; try { storage = options.storage === undefined ? sessionStorage : options.storage; } catch {}
    let rows = {}, allowed = new Set(), actor, epoch = 0, active = 0;
    const pending = new Map(), profiles = new Map(), queue = [], controllers = new Set(), unavailableRPC = new Map();
    try { const raw=storage?.getItem(KEY); if(raw && raw.length<=LIMIT) rows=JSON.parse(raw); } catch {}
    if (!rows || Array.isArray(rows) || typeof rows !== 'object') rows={};
    function persist() {
      const ordered=Object.entries(rows).filter(([k,r])=>allowed.has(k)&&r&&now()-r.at>=0&&now()-r.at<TTL).sort((a,b)=>b[1].at-a[1].at).slice(0,MAX_ROWS);
      while(ordered.length && JSON.stringify(Object.fromEntries(ordered)).length>LIMIT) ordered.pop();
      rows=Object.fromEntries(ordered); try {storage?.setItem(KEY,JSON.stringify(rows));} catch {}
    }
    function cancel() {
      epoch++; for(const c of controllers)c.abort(); controllers.clear();
      for(const job of queue.splice(0))job.reject(Error('Artwork request cancelled'));
      pending.clear(); profiles.clear();
    }
    function holdings(ship, collections) {
      cancel(); if(actor && actor!==ship)rows={}; actor=ship;
      allowed=new Set();
      for(const c of collections)for(const t of c.tokens){try{allowed.add(identity(c,t));}catch{}}
      persist();
    }
    function clear() {cancel();actor=undefined;allowed.clear();rows={};try{storage?.removeItem(KEY);}catch{}}
    async function json(url, init={}, limit=LIMIT) {
      const controller=new AbortController(); controllers.add(controller);
      const timer=setTimeout(()=>controller.abort(),10000);
      try {
        const r=await fetcher(url,{...init,credentials:'omit',referrerPolicy:'no-referrer',signal:controller.signal,cache:'no-store'});
        if(!r.ok)throw Error('Artwork source unavailable');
        const reader=r.body.getReader(), chunks=[]; let length=0;
        try {while(true){const {done,value}=await reader.read();if(done)break;length+=value.length;if(length>limit)throw Error('Artwork metadata is too large');chunks.push(value);}}
        finally {await reader.cancel();}
        const bytes=new Uint8Array(length);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
        return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));
      } finally {clearTimeout(timer);controllers.delete(controller);}
    }
    async function metadata(c,t) {
      const rpc=RPC[c.chain]; if(unavailableRPC.has(rpc)&&now()-unavailableRPC.get(rpc)<60000)throw Error('Artwork RPC unavailable');
      let result;
      try {
        result=await json(rpc,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({jsonrpc:'2.0',id:1,method:'eth_call',params:[{to:c.contract,data:'0xc87b56dd'+BigInt(t.id).toString(16).padStart(64,'0')}, c.checkpoint?'0x'+BigInt(c.checkpoint).toString(16):'finalized']})},LIMIT*2+1024);
        if(result.error)throw Error('Artwork RPC unavailable');
      }catch(error){unavailableRPC.set(rpc,now());throw error;}
      const uri=abiString(result.result);let data;
      if(uri.startsWith('data:application/json')) {
        const comma=uri.indexOf(','),head=uri.slice(0,comma),body=uri.slice(comma+1);
        if(!/^data:application\/json(?:;charset=utf-8)?(?:;base64)?$/i.test(head))throw Error('Unsupported metadata encoding');
        const decoded=head.endsWith(';base64')?new TextDecoder('utf-8',{fatal:true}).decode(Uint8Array.from(atob(body),c=>c.charCodeAt(0))):decodeURIComponent(body);
        if(decoded.length>LIMIT)throw Error('Artwork metadata is too large');data=JSON.parse(decoded);
      } else data=await json(resource(uri));
      return {name:typeof data.name==='string'?data.name.slice(0,160):`${c.name||c.id} #${t.id}`,image:resource(data.image||data.image_url)};
    }
    async function lookup(c,t,key,version) {
      if(!profiles.has(c.id))profiles.set(c.id, json(`/gater/${encodeURIComponent(c.id)}/info`));
      const profile=await profiles.get(c.id), source=profile.brand?.artworkTemplate||'';
      if(version!==epoch || !allowed.has(key))throw Error('Artwork request cancelled');
      if(source)return {name:`${c.name||c.id} #${t.id}`,image:template(source,t.id)};
      const saved=rows[key];
      if(saved && saved.source===source && now()-saved.at>=0 && now()-saved.at<TTL) {
        try{return {name:String(saved.data.name).slice(0,160),image:resource(saved.data.image)};}catch{delete rows[key];}
      }
      const data=await metadata(c,t);
      if(version!==epoch || !allowed.has(key))throw Error('Artwork request cancelled');
      rows[key]={at:now(),source,data};persist();return data;
    }
    function pump() {
      while(active<2 && queue.length){const job=queue.shift();active++;
        Promise.resolve().then(job.work).then(job.resolve,job.reject).finally(()=>{active--;pump();});}
    }
    function load(c,t) {
      let key;try{key=identity(c,t);}catch(error){return Promise.reject(error);}
      if(!actor || !allowed.has(key))return Promise.reject(Error('NFT is not in the signed-in ship’s holdings'));
      if(pending.has(key))return pending.get(key);
      const version=epoch;
      const promise=new Promise((resolve,reject)=>{queue.push({resolve,reject,work:()=>{
        if(version!==epoch || !allowed.has(key))throw Error('Artwork request cancelled');
        return lookup(c,t,key,version);
      }});});
      pending.set(key,promise);pump();return promise;
    }
    return {holdings,load,clear};
  }
  return {create,resource,template,abiString,identity};
})();
if(typeof module!=='undefined')module.exports=GaterArtwork;
