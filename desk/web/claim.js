'use strict';
let state, pending, selection, working = false;
const artwork = GaterArtwork.create();
let artworkObserver;
const $ = (id) => document.getElementById(id);
const node = (tag, text, cls) => { const el = document.createElement(tag); if (text !== undefined) el.textContent = text; if (cls) el.className = cls; return el; };
const selected = GaterCommunity.selected();
GaterCommunity.load(true).catch((error) => notice(error.message, true));
function notice(text, error = false) { $('notice').textContent = text; $('notice').className = error ? 'error' : ''; }
async function request(path, body) {
  const response = await fetch(path, {
    method: body ? 'POST' : 'GET', credentials: 'same-origin',
    headers: body ? {'Content-Type': 'application/json', 'X-Gater': '1'} : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  if (response.status === 401) {
    state = pending = undefined; artwork.clear(); artworkObserver?.disconnect(); $('collections').replaceChildren();
    location.replace(selected ? `/gater/${encodeURIComponent(selected)}` : '/gater');
    throw new Error('Sign in with your ship again.');
  }
  const data = await response.json();
  if (!response.ok) { const error=new Error(data.error || `Request failed (${response.status})`); error.status=response.status; throw error; }
  return data;
}
function acceptState(view) {
  state=view;
  artwork.holdings(state.ship, selected ? state.collections.filter(c=>c.id===selected) : state.collections);
}
async function api(body) {
  acceptState(await request(body ? '/gater/action' : '/gater/me', body));
  pending = undefined; render();
}
async function busy(work) {
  if(working)return; working=true; document.querySelectorAll('button').forEach((b) => b.disabled = true);
  try { await work(); } catch (error) { notice(error.message, true); }
  finally { working=false; if (state) render(); }
}
function claimIntent(view, collection, token) {
  const c=view.collections.find(c=>c.id===collection),t=c?.tokens.find(t=>t.id===token);
  return JSON.stringify([view.ship,c?.group,c?.fresh,t?.ship,t?.owner,t?.generation,c?.tokens.filter(t=>t.ship===view.ship).map(t=>t.id)]);
}
async function act(action, collection, token, extra = {}) {
  if (!state) return;
  await busy(async () => {
    const before = claimIntent(state, collection, token);
    for(let attempt=0;attempt<4;attempt++) {
      try { await api({action,collection,token,revision:state.collections.find(c=>c.id===collection)?.tokens.find(t=>t.id===token)?.revision||state.revision,...extra}); selection=undefined; break; }
      catch(error) {
        if(error.status!==409 || !error.message.startsWith('State changed.')) throw error;
        const latest=await request('/gater/me');
        if(claimIntent(latest,collection,token)!==before){acceptState(latest);selection=undefined;throw Error('This NFT’s eligibility or association changed. Choose from the updated cards.');}
        acceptState(latest);
        if(attempt===3)throw Error('Ownership is synchronizing. Your choice is still selected; try confirming in a moment.');
      }
    }
    notice(action === 'release' ? 'Association released.' : 'Association saved. Group access follows the host’s delivery settings.');
  });
}
async function prepareWallet(collection, token) {
  if (!state) return;
  await busy(async () => {
    let challenge;
    try { challenge = await request('/gater/wallet-challenge', {collection, token, revision: state.collections.find(c=>c.id===collection)?.tokens.find(t=>t.id===token)?.revision||state.revision}); } catch(error) { if(error.status===409 && error.message.startsWith('State changed.')) { await api(); throw Error('This NFT’s eligibility or association changed. Select it again to review a fresh authorization.'); } throw error; }
    pending = {...challenge, collection, token};
    notice('Review the message, then authorize it with the NFT owner wallet.');
  });
}
async function walletClaim(signature) {
  if (!pending) return;
  const p = pending;
  if (!/^0x[0-9a-fA-F]{130}$/.test(signature)) throw new Error('Provide a 65-byte Ethereum signature starting with 0x.');
  try { await api({action: 'wallet-claim', collection: p.collection, token: p.token,
    revision: p.revision, expires: p.expires, signature}); }
  catch(error) { if(error.status===409 && error.message.startsWith('State changed.')) { pending=undefined; await api(); throw Error('Ownership or the existing association changed after signing. Review a new authorization before signing again.'); } throw error; }
  notice('Wallet authorization accepted. Association saved.');
}
function walletPanel() {
  const panel = $('wallet-authorization'); panel.replaceChildren(); panel.hidden = !pending;
  if (!pending) return;
  panel.append(node('h2', `Authorize NFT #${pending.token}`), node('p', `Sign with ${pending.owner}`, 'muted'));
  panel.append(node('p', 'This changes the linked ship only. No transaction, gas payment, or NFT transfer. Regular Ethereum key wallets are supported. For a smart-contract wallet, release the association from the currently linked ship first.'));
  const message = node('textarea'); message.readOnly = true; message.rows = 15;
  message.setAttribute('aria-label', 'Exact message to sign'); message.value = pending.message;
  panel.append(message);
  const sign = node('button', 'Sign with owner wallet');
  sign.addEventListener('click', () => busy(async () => {
    const provider = window.ethereum;
    if (!provider?.request) throw new Error('No wallet detected. Use a wallet-enabled browser, or sign the exact message elsewhere and paste the signature below.');
    const p = pending;
    const accounts = await provider.request({method: 'eth_requestAccounts'});
    const account = accounts.find((a) => a.toLowerCase() === p.owner.toLowerCase());
    if (!account) throw new Error('Select the current NFT owner account in your wallet and try again.');
    const hex = '0x' + Array.from(new TextEncoder().encode(p.message), (b) => b.toString(16).padStart(2, '0')).join('');
    const signature = await provider.request({method: 'personal_sign', params: [hex, account]});
    if (pending !== p) throw new Error('Claim details changed. Request a new authorization.');
    await walletClaim(signature);
  }));
  panel.append(sign);
  const form = node('form'); const label = node('label', 'Or paste the signed message signature');
  const input = node('input'); input.name = 'signature'; input.required = true; input.autocomplete = 'off';
  input.placeholder = '0x…'; label.append(input);
  form.append(label, node('button', 'Verify signature and move claim'));
  form.addEventListener('submit', (e) => { e.preventDefault(); const signature = input.value.trim(); busy(() => walletClaim(signature)); });
  panel.append(form);
  const cancel = node('button', 'Cancel', 'quiet');
  cancel.addEventListener('click', () => { pending = undefined; notice('Authorization cancelled.'); render(); }); panel.append(cancel);
  panel.append(node('p', 'Authorization expires after five minutes. Ownership or claim changes can invalidate it sooner; refresh and request a new message.', 'muted'));
}
function nftCard(c,t) {
      const mine=t.ship===state.ship,chosen=selection?.collection===c.id&&selection.token===t.id;
      const tile=node(mine?'article':'button',undefined,'nft-card'+(chosen?' selected':''));if(!mine){tile.type='button';tile.setAttribute('aria-pressed',String(chosen));}
      const status=t.ship?'Linked to '+t.ship:'unlinked';
      tile.disabled=working||(!c.fresh&&!mine);tile.setAttribute('aria-label',`NFT #${t.id} · ${status}`);
      const art=node('span',undefined,'nft-art');const placeholder=node('span','#'+t.id);art.append(placeholder);
      const detail=node('span',undefined,'nft-description'),name=node('strong','#'+t.id);detail.append(name,node('small',status));
      tile.loadArtwork=()=>artwork.load(c,t).then(data=>{
        if(!tile.isConnected)return;
        name.textContent=data.name;tile.setAttribute('aria-label',`${data.name} · ${status}`);
        const img=node('img');img.alt=data.name;img.loading='lazy';img.referrerPolicy='no-referrer';
        img.onload=()=>{placeholder.hidden=true;};img.onerror=()=>{img.remove();placeholder.hidden=false;};img.src=data.image;art.append(img);
      }).catch(()=>{if(tile.isConnected)art.title='Artwork unavailable from this source. You can still claim this NFT.';});
      tile.append(art,detail);if(!mine)tile.addEventListener('click',()=>{selection={collection:c.id,token:t.id};render();document.querySelector('.nft-card.selected')?.focus({preventScroll:true});});
  artworkObserver.observe(tile);return tile;
}
function render() {
  artworkObserver?.disconnect();
  artworkObserver=new IntersectionObserver(entries=>{
    for(const entry of entries)if(entry.isIntersecting){artworkObserver.unobserve(entry.target);entry.target.loadArtwork();}
  },{rootMargin:'120px'});
  $('identity').textContent=state.ship+' ▾'; $('identity').disabled=false; $('logout').disabled=false;
  $('host-config').hidden=state.ship!==state.host; $('refresh').disabled=working;
  const list=$('collections');list.replaceChildren();
  const collections=selected?state.collections.filter(c=>c.id===selected):state.collections;
  if(!collections.length)list.append(node('p','No communities are available here yet.','muted'));
  for(const c of collections){
    const card=node('article',undefined,'collection'),heading=node('div',undefined,'section-heading');
    heading.append(node('h3',c.name||c.id),node('span',`${c.chain==='8453'?'Base':'Ethereum'} · ${c.tokens.length} owned`,'badge'));card.append(heading);
    if(!c.fresh)card.append(node('p','Ownership is synchronizing. You can release an association now; new claims resume when the data is current.','muted'));
    if(!c.tokens.length)card.append(node('p','No eligible NFTs are associated with this Urbit ID.','muted'));
    const linked=c.tokens.find(t=>t.ship===state.ship);
    const membership=node('section',undefined,'linked-membership');
    membership.append(node('h4','Linked to '+state.ship));
    const slot=node('div',undefined,'linked-slot');
    if(linked){
      slot.append(nftCard(c,linked));
      const detail=node('div');detail.append(node('p','Your membership link','eyebrow'),node('h3',c.name||c.id),node('p','This NFT connects your ship to this community.','muted'));
      const release=node('button','Release link','quiet');release.disabled=working;release.addEventListener('click',()=>act('release',c.id,linked.id));detail.append(release);slot.append(detail);
    }else{
      const empty=node('div','+','empty-nft-slot');empty.setAttribute('aria-hidden','true');slot.append(empty);
      const detail=node('div');detail.append(node('p','No NFT linked','eyebrow'),node('h3',`Link a ${c.id} for access`),node('p','Choose an unlinked NFT below, then confirm your membership.','muted'));slot.append(detail);
    }
    membership.append(slot);card.append(membership);
    card.append(node('h4','Your NFTs'));
    const grid=node('div',undefined,'nft-grid');
    for(const t of [...c.tokens].filter(t=>t.ship!==state.ship).sort((a,b)=>BigInt(a.id)<BigInt(b.id)?-1:BigInt(a.id)>BigInt(b.id)?1:0))grid.append(nftCard(c,t));
    card.append(grid);
    const chosen=c.tokens.find(t=>selection?.collection===c.id&&selection.token===t.id);
    if(chosen){
      const mine=chosen.ship===state.ship,bar=node('div',undefined,'claim-confirmation'),copy=node('div');
      copy.append(node('strong',`${mine?'Release':'Selected'} #${chosen.id}`),node('p',mine?'Group access is removed according to this community’s policy.':chosen.ship?'The owner wallet must authorize this occupied association.':'Associate this NFT with '+state.ship+'.','small muted'));
      const button=node('button',mine?'Release membership':chosen.ship?'Authorize with wallet':'Confirm membership',mine?'quiet':'');button.disabled=working;
      button.addEventListener('click',()=>chosen.ship&&!mine?prepareWallet(c.id,chosen.id):act(mine?'release':'claim',c.id,chosen.id));bar.append(copy,button);card.append(bar);
    }
    list.append(card);
  }
  walletPanel();
}
$('identity').addEventListener('click',()=>{const menu=$('identity').closest('.identity-menu');menu.classList.toggle('open');$('identity').setAttribute('aria-expanded',String(menu.classList.contains('open')));});
$('logout').addEventListener('click',()=>busy(async()=>{const response=await fetch('/~/logout',{method:'POST',credentials:'same-origin'});if(!response.ok)throw Error('Sign out failed. Try again.');artwork.clear();artworkObserver?.disconnect();location.replace(selected?`/gater/${encodeURIComponent(selected)}`:'/gater');}));
$('refresh').addEventListener('click',()=>busy(()=>api()));
api().catch(error=>notice(error.message,true));
