'use strict';
let state, pending;
const $ = (id) => document.getElementById(id);
const node = (tag, text, cls) => { const el = document.createElement(tag); if (text !== undefined) el.textContent = text; if (cls) el.className = cls; return el; };
const collectionHint = new URLSearchParams(location.search).get('collection');
const selected = collectionHint && /^[a-z][a-z0-9-]*$/.test(collectionHint) ? collectionHint : null;
function notice(text, error = false) { $('notice').textContent = text; $('notice').className = error ? 'error' : ''; }
async function request(path, body) {
  const response = await fetch(path, {
    method: body ? 'POST' : 'GET', credentials: 'same-origin',
    headers: body ? {'Content-Type': 'application/json', 'X-Gater': '1'} : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  if (response.status === 401) {
    state = pending = undefined; $('collections').replaceChildren();
    location.replace(selected ? `/gater?${new URLSearchParams({collection: selected})}` : '/gater');
    throw new Error('Sign in with your ship again.');
  }
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || `Request failed (${response.status})`);
  return data;
}
async function api(body) {
  state = await request(body ? '/gater/action' : '/gater/me', body);
  pending = undefined; render();
}
async function busy(work) {
  document.querySelectorAll('button').forEach((b) => b.disabled = true);
  try { await work(); } catch (error) { notice(error.message, true); }
  finally { if (state) render(); }
}
async function act(action, collection, token, extra = {}) {
  if (!state) return;
  await busy(async () => {
    await api({action, collection, token, revision: state.revision, ...extra});
    notice(action === 'release' ? 'Association released.' : 'Association saved. Group access remains in preview.');
  });
}
async function prepareWallet(collection, token) {
  if (!state) return;
  await busy(async () => {
    const challenge = await request('/gater/wallet-challenge', {collection, token, revision: state.revision});
    pending = {...challenge, collection, token};
    notice('Review the message, then authorize it with the NFT owner wallet.');
  });
}
async function walletClaim(signature) {
  if (!pending) return;
  const p = pending;
  if (!/^0x[0-9a-fA-F]{130}$/.test(signature)) throw new Error('Provide a 65-byte Ethereum signature starting with 0x.');
  await api({action: 'wallet-claim', collection: p.collection, token: p.token,
    revision: p.revision, expires: p.expires, signature});
  notice('Wallet authorization accepted. Association saved.');
}
function walletPanel() {
  const panel = $('wallet-authorization'); panel.replaceChildren(); panel.hidden = !pending;
  if (!pending) return;
  panel.append(node('h2', `Authorize NFT #${pending.token}`), node('p', `Sign with ${pending.owner}`, 'muted'));
  panel.append(node('p', 'This changes the linked ship only. No transaction, gas payment, or NFT transfer. Regular Ethereum key wallets are supported; smart-contract wallets need linked-ship approval.'));
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
function render() {
  $('identity').textContent = state.ship;
  $('host-config').hidden = state.ship !== state.host;
  $('refresh').disabled = false;
  const list = $('collections'); list.replaceChildren();
  if (!state.collections.length) list.append(node('p', 'The host has not configured any collections yet.', 'muted'));
  if (selected && !state.collections.some((c) => c.id === selected)) list.append(node('p', 'The collection from your link is not configured here. Available collections are shown below.', 'muted'));
  const collections = [...state.collections].sort((a, b) => Number(b.id === selected) - Number(a.id === selected));
  for (const c of collections) {
    const card = node('article', undefined, 'collection');
    card.append(node('h3', c.name || c.id), node('span', `${c.chain === '8453' ? 'Base' : 'Ethereum'} · ${c.group}`, 'badge'));
    if (!c.fresh) card.append(node('p', 'Ownership data is not current. Claiming will be available after synchronization.', 'muted'));
    if (!c.tokens.length) card.append(node('p', 'No eligible NFTs are associated with this Urbit ID.', 'muted'));
    for (const t of [...c.tokens].sort((a,b) => BigInt(a.id) < BigInt(b.id) ? -1 : BigInt(a.id) > BigInt(b.id) ? 1 : 0)) {
      const row = node('div', undefined, 'token'); const detail = node('div');
      detail.append(node('strong', `#${t.id}`), node('div', t.ship ? `Associated with ${t.ship}` : 'Available to claim', 'muted'));
      const mine = t.ship === state.ship;
      const button = node('button', mine ? 'Release' : t.ship ? 'Authorize with owner wallet' : 'Claim membership', mine ? 'quiet' : '');
      button.disabled = !c.fresh && !mine;
      button.addEventListener('click', () => t.ship && !mine ? prepareWallet(c.id, t.id) : act(mine ? 'release' : 'claim', c.id, t.id));
      row.append(detail, button); card.append(row);
      if (mine) {
        const transfer = node('details'); transfer.append(node('summary', `Transfer #${t.id} to another ship`));
        const form = node('form'); const label = node('label', 'Receiving Urbit ID');
        const input = node('input'); input.name = 'target'; input.required = true; input.placeholder = '~sampel-palnet';
        label.append(input); const submit = node('button', 'Approve transfer'); submit.disabled = !c.fresh;
        form.append(label, node('p', 'The receiving ship must have the same owner and no other claim in this collection. This removes your association.', 'muted'), submit);
        form.addEventListener('submit', (e) => { e.preventDefault(); act('reassign', c.id, t.id, {target: input.value.trim()}); });
        transfer.append(form); card.append(transfer);
      } else if (t.ship) card.append(node('p', `Or ask ${t.ship} to approve a transfer from its own claim page. Shared ownership alone cannot replace an occupied claim.`, 'muted'));
    }
    list.append(card);
  }
  walletPanel();
}
$('refresh').addEventListener('click', () => busy(() => api()));
api().catch((error) => notice(error.message, true));
