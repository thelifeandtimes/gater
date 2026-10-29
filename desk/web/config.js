'use strict';
let state, editing = null, busy = false, dirty = false;
const $ = (id) => document.getElementById(id);
const form = $('configure'), field = (name) => form.elements.namedItem(name);
const brandKeys = ['title','subtitle','claimTitle','claimSubtitle','header','avatar','background','surface','text','muted','accent','secondary','tertiary','raised','error','selection','link','border','palette','fontDisplay','fontBody','fontMono','fontDisplayURL','fontBodyURL','fontMonoURL','spacing','rounding','footer','artworkTemplate','themeMode'];
const policyKeys = ['id','name','chain','contract','group','role','recognition','removeMembership','message','manualApproval','removalMessage'];
const node = (tag, text, cls) => { const el = document.createElement(tag); if (text !== undefined) el.textContent = text; if (cls) el.className = cls; return el; };
const link = (text, href) => { const a = node('a', text); a.href = href; a.target = '_blank'; a.rel = 'noopener noreferrer'; return a; };
function notice(text, error = false) {
  for (const id of ['notice','editor-notice']) { $(id).textContent = text; $(id).className = error ? 'error' : ''; }
}
async function api(body) {
  const response = await fetch(body ? '/gater/config/action' : '/gater/config/state', {
    method: body ? 'POST' : 'GET', credentials:'same-origin',
    headers: body ? {'Content-Type':'application/json','X-Gater':'1'} : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  if (response.status === 401 || response.status === 403) {
    $('admin').hidden = true; location.replace('/~/login?redirect=/gater/config');
    throw new Error('Sign in as this host to manage communities.');
  }
  const data = await response.json();
  if (!response.ok) { const error=new Error(data.error || `Request failed (${response.status})`); error.status=response.status; throw error; }
  state = data; render(); return data;
}
async function run(work) {
  if (busy) return;
  busy = true; buttons();
  try { await work(); } catch (error) { notice(error.message, true); }
  finally { busy = false; buttons(); }
}
function buttons() {
  document.querySelectorAll('button').forEach((b) => b.disabled = busy);
  $('create-group').disabled = busy || !/^[a-z][a-z0-9-]{0,63}$/.test(field('id').value) || !field('name').value.trim();
  $('create-role').disabled = busy || !field('group').value;
  document.querySelectorAll('[data-requires-audit]').forEach(b=>b.disabled=busy||!state?.ownershipAudit?.verified||!state?.delivery?.enabled||b.dataset.sent==='true');
}
function groupURL(group) { return `/apps/groups/group/${encodeURIComponent(`${state.host}/${group}`)}`; }
function inviteURL(id) { return `${(state.baseUrl || location.origin).replace(/\/$/,'')}/gater/${encodeURIComponent(id)}`; }
function options(select, rows, value, prompt) {
  select.replaceChildren(); const blank = node('option', prompt); blank.value = ''; select.append(blank);
  for (const row of rows) { const option = node('option', `${row.name || row.id} · ${row.id}`); option.value = row.id; select.append(option); }
  if (value && !rows.some((row) => row.id === value)) {
    const missing = node('option', `${value} (not found on host)`); missing.value = value; select.append(missing);
  }
  select.value = value || '';
}
function groupChoices(group = field('group').value, role = field('role').value) {
  options(field('group'), state.groups || [], group, 'Choose a hosted group');
  roleChoices(role);
}
function roleChoices(role = '') {
  const group = (state.groups || []).find((g) => g.id === field('group').value);
  options(field('role'), group?.roles || [], role, 'Choose a membership role');
}
function preview() {
  const b = Object.fromEntries(brandKeys.map((key) => [key, field(key).value]));
  GaterCommunity.apply(b, $('brand-preview'));
  const claim = $('preview-page').value === 'claim';
  $('preview-name').textContent = field('name').value || 'Your community';
  $('preview-title').textContent = (claim ? b.claimTitle || b.title : b.title) || (claim ? 'Choose your association.' : 'Claim your group membership.');
  $('preview-subtitle').textContent = (claim ? b.claimSubtitle || b.subtitle : b.subtitle) || 'Link an NFT you own to your Urbit ID.';
  $('brand-preview').querySelector('.preview-button').textContent = claim ? 'Claim membership' : 'Continue with EAuth';
  GaterCommunity.image($('preview-header'), b.header, '');
  GaterCommunity.image($('preview-avatar'), b.avatar, 'Collection avatar');
  const id = field('id').value || '<collection-id>';
  $('group-hint').textContent = `Creates a private group named ${id} with a ${id}-chat channel. Existing groups are never overwritten.`;
  const shares = $('share-links'); shares.replaceChildren();
  if (editing) {
    const url = inviteURL(editing);
    shares.append(node('h3','Share your community'), link('Open invite page ↗',url), node('p',url,'mono small'), link('Open claim page ↗',url+'/claim'));
    const copy = node('button','Copy invite link','quiet'); copy.type='button';
    copy.addEventListener('click', () => run(async () => { await navigator.clipboard.writeText(url); notice('Invite link copied.'); })); shares.append(copy);
  }
  buttons();
}
function openEditor(c = null) {
  editing = c?.id || null; dirty = false; form.reset();
  for (const key of policyKeys) if (c && c[key] !== undefined) {if(field(key).type==='checkbox')field(key).checked=!!c[key];else field(key).value = String(c[key]);}
  const appearance=GaterCommunity.resolved(c?.brand||{});
  for (const key of brandKeys) field(key).value = key==='themeMode'?GaterCommunity.themeMode(c?.brand):key.startsWith('font')?GaterCommunity.fontOverride(c?.brand||{},key):appearance[key] || '';
  field('id').readOnly = !!c; field('contract').readOnly = !!c; field('chain').disabled = !!c;
  const indexing = (state.rpc?.indexes || []).find(row => row.id === c?.id) || defaultIndex(c?.chain, c?.contract);
  field('indexMode').value=indexing.mode; field('indexStart').value=indexing.start; field('indexReview').value=indexing.review;
  indexingVisibility();
  $('role-id').value=''; $('role-name').value='';
  groupChoices(c?.group || '', c?.role || '');
  $('editor-title').textContent = c ? `Edit ${c.name || c.id}` : 'Create a gated community';
  $('delete').hidden = !c; $('community-list').hidden = true; $('editor').hidden = false;
  notice(''); preview(); $('editor').scrollIntoView({behavior:'smooth',block:'start'});
  field(c ? 'name' : 'id').focus();
}
async function closeEditor() {
  if (dirty && !await confirmAction('Discard changes?', 'Your unsaved edits will be lost.', 'Discard changes')) return;
  editing = null; dirty = false; $('editor').hidden = true; $('community-list').hidden = false;
}
function confirmAction(title, description, label = 'Continue') {
  const dialog = $('confirm-action'); $('confirm-title').textContent = title;
  $('confirm-description').textContent = description; $('confirm-button').textContent = label;
  dialog.returnValue = 'cancel'; dialog.querySelectorAll('button').forEach(b => b.disabled = false);
  dialog.showModal(); return new Promise(resolve => dialog.addEventListener('close', () => resolve(dialog.returnValue === 'confirm'), {once:true}));
}
function hostChoices() {
  const select = $('host-choice'), current = $('settings').elements.baseUrl.value;
  const rows = [...new Set([...(state.hostUrls || []), state.baseUrl, location.origin].filter(Boolean))];
  select.replaceChildren();
  for (const url of rows) { const option=node('option',url + (url===location.origin ? ' · current browser' : '')); option.value=url; select.append(option); }
  const custom=node('option','Custom URL…'); custom.value=''; select.append(custom); select.value=rows.includes(current)?current:'';
}
function defaultIndex(chain, contract) {
  return String(chain)==='8453' && contract?.toLowerCase()==='0x7465e492a183f16c0805e57262898c7bec11808a'
    ? {mode:'events-supply',start:'52544634',review:'Reviewed Nockmilio ERC721A mint/transfer/burn history; see docs/nockmilio-verification.md.'}
    : {mode:'enumerable',start:'0',review:''};
}
function indexingVisibility() { $('event-indexing').hidden=field('indexMode').value!=='events-supply'; }
function render() {
  $('identity').textContent = `${state.ship} · host`;
  if (document.activeElement?.form !== $('settings')) {
    $('settings').elements.baseUrl.value = state.baseUrl;
    $('settings').elements.azimuthAuto.value = String(state.azimuthAuto);
  }
  $('azimuth-status').textContent = state.ownershipAudit?.verified ? `Verified through Ethereum block ${state.ownershipAudit.height}. ${state.ownershipAudit.scope}.` : 'Waiting for a current, complete finalized Azimuth audit. Sending is paused.';
  const bootstrap=state.bootstrap || {}, current=bootstrap.current;
  $('bootstrap-status').textContent=current?`This ship: block ${current.height} · ${current.hash} · fingerprint ${current.digest}. Active anchor: block ${bootstrap.height}${bootstrap.retained?' (retained on this ship)':''}.`:'The ship’s Azimuth bootstrap is unavailable. Wait for Urbit ownership sync.';
  $('trust-bootstrap').hidden=!current || Number(current.height)===0 || current.digest===bootstrap.digest;
  const rpc=state.rpc || {};
  $('rpc-status').textContent=`Infura key: ${rpc.infuraConfigured?'saved':'not set'} · Ethereum: ${rpc.ethereumConfigured?(rpc.ethereumCustom?'custom endpoint':'Infura'):'not configured'} · Base: ${rpc.baseConfigured?(rpc.baseCustom?'custom endpoint':'Infura'):'not configured'}.`;
  const progress=rpc.progress;
  const stages={chain:'checking network',head:'finding finality',checkpoint:'checking previous checkpoint',code:'checking contract',deployment:'checking deployment',supply:'checking supply',enumerable:'checking enumeration',enumerate:'discovering tokens',logs:'reading event history',blocks:'verifying event blocks',inputs:'verifying rollup transactions',owners:'verifying owners',finish:'rechecking finality',done:'saving verified state'};
  const detail=!progress?'': ['owners','enumerate'].includes(progress.stage)?` · ${progress.remaining} token checks remaining`:
    ['logs','blocks','inputs'].includes(progress.stage)?` · block ${Math.min(Number(progress.block),Number(progress.target))} / ${progress.target}`:'';
  $('rpc-progress').textContent=progress?`Checking ${progress.collection} · ${stages[progress.stage] || progress.stage}${detail}.`:'Waiting for the next ownership check.';
  $('rpc-errors').replaceChildren(...(rpc.errors || []).map(e=>node('p',`${e.collection}: ${e.message}`,'error')));
  hostChoices();
  const job = state.provisioning;
  $('provision-status').hidden = !job || job.phase === 'done';
  $('provision-status').textContent = !job ? '' : job.phase === 'failed'
    ? `Last group operation (${job.group}): ${job.error}`
    : `Tlon is creating ${job.kind === 'role' ? 'a role in ' : ''}${job.group}. Stage: ${job.phase}. Refresh to check progress.`;
  const configured = $('configured'); configured.replaceChildren();
  for (const c of state.collections) {
    const card = node('article',undefined,'community-card');
    const top = node('div',undefined,'card-heading'), avatar = node('img',undefined,'card-avatar');
    GaterCommunity.image(avatar,c.brand?.avatar,`${c.name} avatar`);
    const heading = node('div'); heading.append(node('h3',c.name || c.id),node('p',c.id,'mono muted'));
    top.append(avatar,heading); card.append(top);
    const address = node('p',`${c.chain === '8453' ? 'Base' : 'Ethereum'} · ${c.contract.slice(0,8)}…${c.contract.slice(-6)}`,'mono small'); address.title = c.contract; card.append(address);
    const hosted = (state.groups || []).some((g) => g.id === c.group);
    card.append(hosted ? link(`Open ${c.group} ↗`,groupURL(c.group)) : node('p',`Group setup needed · ${c.group}`,'muted'));
    const footer = node('div',undefined,'card-actions'); const edit = node('button','Edit community','quiet'); edit.type='button'; edit.addEventListener('click',()=>openEditor(c));
    footer.append(edit,link('Invite page ↗',`/gater/${encodeURIComponent(c.id)}`)); card.append(footer); configured.append(card);
  }
  const create = node('button','Create a Gated Community +','create-card'); create.type='button'; create.addEventListener('click',()=>openEditor()); configured.append(create);
  const out = $('outbox'); out.replaceChildren(); $('outbox-count').textContent = String(state.outbox.length);
  for (const e of state.outbox) {
    const item = node('div',undefined,'effect');
    item.append(node('strong',`${e.action} · ${e.ship} · ${e.group}`),node('span',e.status==='sent'?'Awaiting observation':e.manualApproval?'Approval required':'Queued automatically','badge'),node('p',e.roles.join(', ') || e.text || 'Membership update','muted'));
    const approve=node('button','Approve & send','quiet');approve.type='button';approve.dataset.requiresAudit='true';approve.disabled=!state.ownershipAudit?.verified||e.status==='sent';approve.dataset.sent=String(e.status==='sent');
    approve.addEventListener('click',()=>run(async()=>{if(!await confirmAction('Send this action?',`${e.action} for ${e.ship} in ${e.group}${e.roles.length?' · '+e.roles.join(', '):''}.`,'Approve & send'))return;await api({action:'approve-effect',fingerprint:e.fingerprint});notice('Approved. Delivery status will confirm the observed result.');}));if(e.manualApproval)item.append(approve);
    out.append(item);
  }
  if (!state.outbox.length) out.append(node('p','No actions are currently proposed.','muted'));
  const delivery=state.delivery||{};
  $('delivery-status').textContent=!state.ownershipAudit?.verified?'Waiting for verified ownership. Actions can be reviewed below.':!delivery.enabled?'Delivery is paused. Enable delivery below to resume.':state.automatic?'Delivery runs automatically unless a community requires approval.':'Delivery requires approval for each action.';
  $('delivery-recheck').hidden=!delivery.active; $('delivery-retry').hidden=delivery.active?.phase!=='failed';
  $('delivery-active').textContent=delivery.active?`In progress: ${delivery.active.action} for ${delivery.active.ship} · ${delivery.active.phase}.${delivery.active.phase==='uncertain'?' Tlon has not confirmed the result. Recheck reads its current state; a DM will not be sent twice.':''}`:'No action is in flight.';
  if(document.activeElement?.form!==$('delivery-settings'))$('delivery-settings').elements.enabled.checked=!!delivery.enabled;
  const receipts=$('delivery-receipts');receipts.replaceChildren();for(const r of delivery.receipts||[])receipts.append(node('p',`${r.action} · ${r.ship} · ${r.group} · ${r.result}`,'small'));
  if(!delivery.receipts?.length)receipts.append(node('p','No deliveries recorded.','muted'));
  const sources = $('sources'); sources.replaceChildren();
  for (const c of state.collections) {
    const row = node('div',undefined,'effect'); row.append(node('strong',c.name || c.id),node('p',c.source ? `${c.source.healthy && c.fresh ? 'Current' : 'Claims paused'} · checkpoint ${c.checkpoint || 'none'} · ${c.source.supply} tokens` : 'Waiting for the first verified checkpoint. Check RPC status above.','muted')); sources.append(row);
  }
  buttons();
}
async function provision(data) {
  await api(data);
  const jobID = state.provisioning?.id;
  notice(data.action === 'create-group' ? 'Creating the group and initial chat…' : 'Creating role…');
  for (let attempt=0; attempt<45; attempt++) {
    const job = state.provisioning;
    if (!job || job.id !== jobID) throw new Error('The provisioning status changed. Refresh hosted groups before continuing.');
    if (job.phase === 'failed') throw new Error(job.error);
    if (job.phase === 'done') {
      groupChoices(job.group,job.kind === 'role' ? job.role : ''); dirty = true;
      notice(job.kind === 'role' ? 'Role created and selected.' : `Group ${job.group} and ${job.group}-chat created and selected.`);
      return;
    }
    await new Promise((resolve)=>setTimeout(resolve,1500)); await api();
  }
  throw new Error('Tlon has not confirmed creation yet. Refresh to check before retrying.');
}
$('create-group').addEventListener('click',()=>run(async()=>{
  const id = field('id').value, name = field('name').value.trim();
  await provision({action:'create-group',group:id,name});
}));
$('create-role').addEventListener('click',()=>run(()=>provision({action:'create-role',group:field('group').value,role:$('role-id').value.trim(),name:$('role-name').value.trim()})));
field('group').addEventListener('change',()=>{ roleChoices(); buttons(); });
form.addEventListener('input',event=>{if(event.target.type==='color')field('themeMode').value='custom';dirty=true;preview();});
form.addEventListener('change',()=>{ dirty=true; preview(); });
$('preview-page').addEventListener('change',preview);
form.addEventListener('submit',(event)=>{event.preventDefault();run(async()=>{
  const current = state.collections.find((c)=>c.id===editing);
  if (current && (current.group!==field('group').value || current.role!==field('role').value) && !await confirmAction('Change the group or role?', 'This clears this collection’s claims. Existing Tlon memberships and roles are kept.', 'Change association')) return;
  const data = Object.fromEntries(policyKeys.map((key)=>[key,field(key).value]));
  data.manualApproval=field('manualApproval').checked; data.removeMembership = data.removeMembership === 'true'; data.action='configure';
  data.indexing={mode:field('indexMode').value,start:field('indexStart').value,review:field('indexReview').value.trim()};
  data.brand=Object.fromEntries(brandKeys.map((key)=>[key,field(key).value]));
  await api(data); dirty=false; await closeEditor(); notice('Community saved. Your invite and claim pages are ready.'); $('notice').scrollIntoView({behavior:'smooth',block:'center'});
});});
$('settings').addEventListener('submit',(event)=>{event.preventDefault();run(async()=>{
  const data=Object.fromEntries(new FormData(event.currentTarget)); data.action='settings'; data.azimuthAuto=data.azimuthAuto==='true'; await api(data); notice('Host settings saved.');
});});
$('delete').addEventListener('click',()=>{ $('delete-description').textContent=`Delete ${state.collections.find((c)=>c.id===editing)?.name || editing}?`; $('confirm-delete').returnValue='cancel'; $('confirm-delete').showModal(); });
$('confirm-delete').addEventListener('close',()=>{ if ($('confirm-delete').returnValue==='delete') run(async()=>{
  const id=editing, signature=c=>JSON.stringify(c&&[...policyKeys.map(k=>c[k]),c.brand]), original=signature(state.collections.find(c=>c.id===id));
  for(let attempt=0;attempt<4;attempt++){try{await api({action:'delete-collection',id,revision:state.revision});break;}catch(error){if(error.status!==409||!error.message.includes('State changed'))throw error;await api();const current=state.collections.find(c=>c.id===id);if(!current)break;if(signature(current)!==original||attempt===3)throw new Error('This community was edited elsewhere. Review its current settings before deleting.');}}
  dirty=false; await closeEditor(); notice('Collection deleted. The Tlon group and its members were kept.');
}); });
for (const id of ['back','cancel']) $(id).addEventListener('click',closeEditor);
$('refresh').addEventListener('click',()=>run(()=>api()));
window.addEventListener('beforeunload',(event)=>{ if(dirty) event.preventDefault(); });
api().catch((error)=>notice(error.message,true));

$('host-choice').addEventListener('change',e=>{ const input=$('settings').elements.baseUrl; if(e.target.value) input.value=e.target.value; else {input.value='';input.focus();} });
function fillPalette(b) { for (const key of brandKeys) if (b[key] !== undefined) field(key).value=b[key]; dirty=true; preview(); }
$('import-palette').addEventListener('click',()=>run(async()=>{ fillPalette({...GaterCommunity.fromProfile(JSON.parse(field('palette').value)),themeMode:'custom'}); notice('Palette applied to the preview. Save to publish.'); }));
$('use-ship-theme').addEventListener('click',()=>run(async()=>{ await GaterCommunity.shipTheme();field('themeMode').value='host';dirty=true;preview();notice('This community will follow the host theme. Save to publish.'); }));
GaterCommunity.followHost();

$('delivery-settings').addEventListener('submit',event=>{event.preventDefault();run(async()=>{await api({action:'delivery-settings',enabled:event.currentTarget.elements.enabled.checked,automatic:true});notice('Delivery settings saved.');});});
setInterval(()=>{if(!document.hidden&&!busy&&!dirty&&!document.querySelector('dialog[open]'))api().catch(()=>{});},10000);

$('brand-preview').addEventListener('image-unavailable',()=>{ $('image-status').textContent='An image could not be loaded. X profile lookup may be unavailable; a direct pbs.twimg.com image URL also works.'; });

$('delivery-recheck').addEventListener('click',()=>run(async()=>{await api({action:'recheck-delivery'});notice('Checked Tlon for the current delivery result.');}));
$('delivery-retry').addEventListener('click',()=>run(async()=>{if(!await confirmAction('Retry rejected action?','Gater will check whether the action is still needed and retry it with current ownership.','Retry action'))return;await api({action:'retry-delivery'});notice('Recovery requested. The receipt will confirm the result.');}));

document.addEventListener('gater-theme',()=>{if(!$('editor').hidden)preview();});

field('indexMode').addEventListener('change',indexingVisibility);
for(const key of ['contract','chain']) field(key).addEventListener('change',()=>{
  if(editing)return;
  const indexing=defaultIndex(field('chain').value,field('contract').value.trim());
  field('indexMode').value=indexing.mode;field('indexStart').value=indexing.start;field('indexReview').value=indexing.review;indexingVisibility();
});
$('rpc-settings').addEventListener('submit',event=>{
  event.preventDefault(); const rpcForm=event.currentTarget;
  run(async()=>{
    const data=Object.fromEntries(new FormData(rpcForm));data.action='rpc-settings';
    for(const key of ['clearInfura','clearEthereum','clearBase'])data[key]=rpcForm.elements[key].checked;
    await api(data);rpcForm.reset();notice('RPC settings saved on this ship. Native ownership checks are starting.');
  });
});

$('trust-bootstrap').addEventListener('click',()=>run(async()=>{
  const snapshot=state.bootstrap?.current;if(!snapshot)return;
  if(!await confirmAction('Trust this Urbit bootstrap?',`Use block ${snapshot.height}, hash ${snapshot.hash}, fingerprint ${snapshot.digest}, as the trusted starting state? Gater will verify the canonical block and all subsequent finalized events. Historical ownership before this block is trusted from Urbit. Existing claims must be released before changing this anchor.`,'Trust bootstrap'))return;
  await api({action:'rpc-bootstrap',...snapshot});notice('Bootstrap trust anchor saved. Canonical ownership verification is starting.');
}));
