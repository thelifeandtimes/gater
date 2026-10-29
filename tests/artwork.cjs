const test = require('node:test');
const assert = require('node:assert/strict');
const art = require('../desk/web/artwork.js');
const KEY='gater.artwork.v1';
const collection={id:'demo',name:'Demo',chain:'8453',contract:'0x'+'a'.repeat(40),checkpoint:'123',tokens:[{id:'7'},{id:'9'}]};
function storage(initial={}) {const data=new Map(Object.entries(initial));return {getItem:k=>data.get(k)||null,setItem:(k,v)=>data.set(k,v),removeItem:k=>data.delete(k)};}
const response=data=>new Response(JSON.stringify(data),{headers:{'Content-Type':'application/json'}});
const abi=text=>'0x'+(32n).toString(16).padStart(64,'0')+BigInt(Buffer.byteLength(text)).toString(16).padStart(64,'0')+Buffer.from(text).toString('hex');
function fixture(overrides={}) {
  const calls=[],store=storage();
  const fetch=async(url,init)=>{calls.push({url,init});
    if(url.endsWith('/info'))return response({brand:overrides.brand||{}});
    if(url.includes('publicnode.com'))return response({result:abi('https://metadata.example/7.json')});
    return response({name:'Example #7',image:'ipfs://bafyexample/7.png'});
  };
  return {calls,store,client:art.create({storage:store,fetch,...overrides})};
}
test('nothing is fetched before authentication or for a token outside current holdings',async()=>{
  const {client,calls}=fixture();
  await assert.rejects(client.load(collection,{id:'7'}));
  client.holdings('~nec',[collection]);
  await assert.rejects(client.load(collection,{id:'8'}));
  await assert.rejects(client.load({...collection,contract:'0x'+'b'.repeat(40)},{id:'7'}));
  assert.equal(calls.length,0);
});
test('direct image pattern requires no metadata/RPC fetch and stores no token metadata',async()=>{
  const {client,calls,store}=fixture({brand:{artworkTemplate:'https://images.example/{id}.png'}});
  client.holdings('~nec',[collection]);
  const data=await client.load(collection,{id:'7'});
  assert.deepEqual(data,{name:'Demo #7',image:'https://images.example/7.png'});
  assert.deepEqual(calls.map(x=>x.url),['/gater/demo/info']);
  assert.equal(store.getItem(KEY),'{}');
});
test('browser RPC binds chain, contract, selected token and finalized indexed block without credentials',async()=>{
  const {client,calls}=fixture();client.holdings('~nec',[collection]);
  assert.equal((await client.load(collection,{id:'7'})).image,'https://ipfs.io/ipfs/bafyexample/7.png');
  assert.equal(calls.length,3);
  const rpc=calls[1],body=JSON.parse(rpc.init.body);
  assert.equal(rpc.url,'https://base-rpc.publicnode.com');
  assert.equal(body.params[0].to,collection.contract);
  assert.equal(body.params[0].data,'0xc87b56dd'+(7n).toString(16).padStart(64,'0'));
  assert.equal(body.params[1],'0x7b');
  for(const call of calls){assert.equal(call.init.credentials,'omit');assert.equal(call.init.referrerPolicy,'no-referrer');assert.equal(call.init.cache,'no-store');}
});
test('metadata is cached in this browser session and reused without RPC',async()=>{
  const {client,store}=fixture();client.holdings('~nec',[collection]);await client.load(collection,{id:'7'});
  const next=fixture({storage:store});next.client.holdings('~nec',[collection]);
  assert.equal((await next.client.load(collection,{id:'7'})).name,'Example #7');
  assert.deepEqual(next.calls.map(x=>x.url),['/gater/demo/info']);
  assert.equal(Object.keys(JSON.parse(store.getItem(KEY))).length,1);
});
test('logout and holdings changes remove stale browser metadata and prevent loading old NFTs',async()=>{
  const {client,store}=fixture();client.holdings('~nec',[collection]);await client.load(collection,{id:'7'});
  client.holdings('~nec',[{...collection,tokens:[{id:'9'}]}]);
  assert.equal(store.getItem(KEY),'{}');await assert.rejects(client.load(collection,{id:'7'}));
  client.clear();assert.equal(store.getItem(KEY),null);await assert.rejects(client.load(collection,{id:'9'}));
});
test('changing authenticated ship clears previous display data',async()=>{
  const {client,store}=fixture();client.holdings('~nec',[collection]);await client.load(collection,{id:'7'});
  client.holdings('~zod',[collection]);assert.equal(store.getItem(KEY),'{}');
});
test('cached metadata expires after a day',async()=>{
  let now=100000000;const {client,store}=fixture({now:()=>now});client.holdings('~nec',[collection]);await client.load(collection,{id:'7'});
  now+=86400001;const next=fixture({storage:store,now:()=>now});next.client.holdings('~nec',[collection]);await next.client.load(collection,{id:'7'});
  assert.equal(next.calls.length,3);
});
test('cache is bounded and unowned entries are pruned',()=>{
  const rows={},tokens=Array.from({length:150},(_,i)=>({id:String(i)}));
  for(const t of tokens)rows[art.identity(collection,t)]={at:Date.now(),data:{name:'Example',image:'https://images.example/'+t.id}};
  rows.foreign={at:Date.now(),data:{}};
  const store=storage({[KEY]:JSON.stringify(rows)}),client=art.create({storage:store});client.holdings('~nec',[{...collection,tokens}]);
  const saved=JSON.parse(store.getItem(KEY));assert.equal(Object.keys(saved).length,128);assert.equal(saved.foreign,undefined);
});
test('logout aborts queued work and late replies cannot repopulate the browser cache',async()=>{
  let release;const store=storage(),client=art.create({storage:store,fetch:()=>new Promise(resolve=>{release=resolve;})});
  client.holdings('~nec',[collection]);const request=client.load(collection,{id:'7'});await new Promise(resolve=>setImmediate(resolve));
  client.clear();release(response({brand:{}}));await assert.rejects(request);assert.equal(store.getItem(KEY),null);
});
test('failed RPC is backed off and cannot block claiming code',async()=>{
  let rpc=0;const client=art.create({storage:storage(),fetch:async url=>{
    if(url.endsWith('/info'))return response({brand:{}});rpc++;return new Response('',{status:403});
  }});client.holdings('~nec',[collection]);
  await assert.rejects(client.load(collection,{id:'7'}));await assert.rejects(client.load(collection,{id:'9'}));assert.equal(rpc,1);
});
test('URLs and token patterns reject executable, credentialed and local resources',()=>{
  for(const value of ['http://images.example/a','javascript:alert(1)','https://user:pass@images.example/a','https://127.0.0.1/a','https://localhost/a','https://host.local/a','https://[::1]/a'])assert.throws(()=>art.resource(value));
  assert.equal(art.resource('ar://example'),'https://arweave.net/example');
  assert.throws(()=>art.template('https://images.example/{id}', '../secret'));
  assert.throws(()=>art.template('https://images.example/static.png','7'));
  assert.equal(art.template('https://images.example/{id}.png',(2n**256n-1n).toString()).includes((2n**256n-1n).toString()),true);
});
test('ABI decoder rejects truncated, oversized and wrong-offset metadata',()=>{
  assert.equal(art.abiString(abi('ipfs://example')),'ipfs://example');
  assert.throws(()=>art.abiString('0x01'));
  assert.throws(()=>art.abiString(abi('hello').slice(0,-2)));
  assert.throws(()=>art.abiString('0x'+(64n).toString(16).padStart(64,'0')+abi('hi').slice(66)));
});
