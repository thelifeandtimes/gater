'use strict';
const {test}=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
let profile={};
const document={getElementById:()=>null};
const context={window:{},document,fetch:async()=>({ok:true,json:async()=>profile}),URL,location:{pathname:'/gater',search:''}};
vm.runInNewContext(fs.readFileSync('desk/web/community.js','utf8'),context);
const ui=context.window.GaterCommunity;
test('new communities inherit the host palette',()=>assert.equal(ui.themeMode({}),'host'));
test('legacy untouched palette inherits; customized palette survives',()=>{
  assert.equal(ui.themeMode({background:'#f6f5ee',accent:'#27633d'}),'host');
  assert.equal(ui.themeMode({background:'#171717',accent:'#b4a0e8'}),'custom');
});
test('network settings control full palette and font; collection typography can override',async()=>{
  profile={colors:{background:'#101820',foreground:'#f4f2e9',accent:'#98c18d',bright_red:'#ff8899'},font:'JetBrainsMono Nerd Font'};
  await ui.shipTheme();
  const theme=ui.resolved({themeMode:'host',background:'#f6f5ee',fontDisplay:'Georgia, serif'});
  assert.equal(theme.background,'#101820');assert.equal(theme.accent,'#98c18d');
  assert.equal(theme.fontBody,'JetBrainsMono Nerd Font, monospace');assert.equal(theme.fontDisplay,'Georgia, serif');
  assert.equal(JSON.parse(theme.palette).bright_red,'#ff8899');
});
test('custom community palette remains independent of synchronized updates',()=>{
  assert.equal(ui.resolved({themeMode:'custom',background:'#171717',text:'#cccccc',accent:'#b4a0e8'}).accent,'#b4a0e8');
});
test('missing profile falls back to Omart colors without retaining old host colors',async()=>{
  profile={};await ui.shipTheme();assert.equal(ui.resolved({themeMode:'host'}).background,'#0c0c0d');
});
test('unsafe imported palette values never enter CSS custom variables',()=>{
  const t=ui.fromProfile({colors:{background:'#171717',foreground:'#cccccc',attack:'url(https://bad)'}});
  assert.equal(JSON.parse(t.palette).attack,undefined);
});

test('legacy default typography inherits network fonts without erasing explicit overrides',async()=>{
  profile={colors:{background:'#101820',foreground:'#f4f2e9'},font:'JetBrainsMono Nerd Font'};await ui.shipTheme();
  assert.equal(ui.resolved({fontBody:ui.defaults.fontBody}).fontBody,'JetBrainsMono Nerd Font, monospace');
  assert.equal(ui.fontOverride({fontBody:ui.defaults.fontBody},'fontBody'),'');
  assert.equal(ui.resolved({themeMode:'host',fontBody:ui.defaults.fontBody}).fontBody,ui.defaults.fontBody);
});
