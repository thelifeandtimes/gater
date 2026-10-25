'use strict';
let state;
const $ = (id) => document.getElementById(id);
const node = (tag, text, cls) => { const el = document.createElement(tag); if (text !== undefined) el.textContent = text; if (cls) el.className = cls; return el; };
function notice(text, error = false) { $('notice').textContent = text; $('notice').className = error ? 'error' : ''; }
async function api(body) {
  const response = await fetch(body ? '/gater/config/action' : '/gater/config/state', {
    method: body ? 'POST' : 'GET', credentials: 'same-origin',
    headers: body ? {'Content-Type': 'application/json', 'X-Gater': '1'} : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  if (response.status === 401 || response.status === 403) {
    state = undefined; $('admin').hidden = true;
    location.replace('/~/login?redirect=/gater/config');
    return false;
  }
  const data = await response.json();
  if (!response.ok) throw new Error(data.error || `Request failed (${response.status})`);
  state = data; render(); return true;
}
function render() {
  $('identity').textContent = `${state.ship} · host`;
  $('settings').elements.baseUrl.value = state.baseUrl;
  $('settings').elements.azimuthAuto.value = String(state.azimuthAuto);
  const configured = $('configured'); configured.replaceChildren();
  for (const c of state.collections) {
    const row = node('article', undefined, 'collection');
    row.append(node('h3', c.name || c.id), node('p', `${c.group} · ${c.role} · ${c.recognition}`, 'muted'));
    const edit = node('button', 'Edit collection', 'quiet'); edit.type = 'button';
    edit.addEventListener('click', () => {
      for (const name of ['id', 'name', 'chain', 'contract', 'group', 'role', 'recognition', 'removeMembership', 'message']) {
        $('configure').elements[name].value = String(c[name]);
      }
      $('configure').elements.id.focus();
    });
    row.append(edit); configured.append(row);
  }
  if (!state.collections.length) configured.append(node('p', 'No collections configured yet.', 'muted'));
  const out = $('outbox'); out.replaceChildren();
  for (const e of state.outbox) {
    const item = node('div', undefined, 'effect');
    item.append(node('strong', `${e.action} · ${e.ship} · ${e.group}`), node('p', e.roles.join(', ') || e.text || e.status, 'muted')); out.append(item);
  }
  if (!state.outbox.length) out.append(node('p', 'No pending actions.', 'muted'));
}
for (const id of ['settings', 'configure']) $(id).addEventListener('submit', async (event) => {
  event.preventDefault();
  if (!state) return;
  const form = event.currentTarget;
  const data = Object.fromEntries(new FormData(form)); data.action = id;
  if (id === 'configure') data.removeMembership = data.removeMembership === 'true';
  if (id === 'settings') data.azimuthAuto = data.azimuthAuto === 'true';
  document.querySelectorAll('button').forEach((b) => b.disabled = true);
  try { if (await api(data)) notice('Settings saved.'); } catch (error) { notice(error.message, true); }
  finally { document.querySelectorAll('button').forEach((b) => b.disabled = false); }
});
api().catch((error) => notice(error.message, true));
