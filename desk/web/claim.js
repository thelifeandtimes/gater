'use strict';
let state;
const $ = (id) => document.getElementById(id);
const node = (tag, text, cls) => { const el = document.createElement(tag); if (text !== undefined) el.textContent = text; if (cls) el.className = cls; return el; };
const collectionHint = new URLSearchParams(location.search).get('collection');
const selected = collectionHint && /^[a-z][a-z0-9-]*$/.test(collectionHint) ? collectionHint : null;
function notice(text, error = false) { $('notice').textContent = text; $('notice').className = error ? 'error' : ''; }
async function api(body) {
  const response = await fetch(body ? '/gater/action' : '/gater/me', {
    method: body ? 'POST' : 'GET', credentials: 'same-origin',
    headers: body ? {'Content-Type': 'application/json', 'X-Gater': '1'} : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  if (response.status === 401) {
    state = undefined; $('collections').replaceChildren();
    location.replace(selected ? `/gater?${new URLSearchParams({collection: selected})}` : '/gater');
    return false;
  }
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || `Request failed (${response.status})`);
  state = data; render(); return true;
}
async function act(action, collection, token) {
  if (!state) return;
  const revision = state.revision;
  document.querySelectorAll('button').forEach((b) => b.disabled = true);
  try {
    if (await api({action, collection, token, revision})) {
      notice(action === 'claim' ? 'Association saved. Your host can review the queued membership changes.' : 'Association released.');
    }
  } catch (error) { notice(error.message, true); }
  finally { document.querySelectorAll('button').forEach((b) => b.disabled = false); if (state) render(); }
}
function render() {
  $('identity').textContent = state.ship;
  $('host-config').hidden = state.ship !== state.host;
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
      const button = node('button', mine ? 'Release' : t.ship ? 'Move to this ship' : 'Claim membership', mine ? 'quiet' : '');
      button.disabled = !c.fresh && !mine;
      button.addEventListener('click', () => act(mine ? 'release' : 'claim', c.id, t.id));
      row.append(detail, button); card.append(row);
    }
    list.append(card);
  }
}
$('refresh').addEventListener('click', () => api().catch((error) => notice(error.message, true)));
api().catch((error) => notice(error.message, true));
