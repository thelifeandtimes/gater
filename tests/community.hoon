::  Public presentation, routing, provisioning and collection retirement.
=/  m  (strand ,vase)
=/  now  ~2026.10.28
~|  %reserved-and-invalid-identifiers
?>  (valid-id 'nockmilio')
?>  !(valid-id 'config')
?>  !(valid-id 'bad/id')
?>  !(valid-id '')
~|  %scoped-routes
?>  =(%landing (route '/gater/nockmilio'))
?>  =(%claim (route '/gater/nockmilio/claim'))
?>  =(%claim (route '/gater/nockmilio/claim/?x=y'))
?>  =(%info (route '/gater/nockmilio/info'))
?>  =(%missing (route '/gater/config/claim'))
?>  =(%missing (route '/gater/nockmilio/config'))
?>  =('/gater/nockmilio' (landing-url '/gater/nockmilio/claim?redirect=https://evil.example'))
~|  %browser-artwork-pattern
=/  parsed  (parse-brand (need (de:json:html '{"artworkTemplate":"https://example.com/{id}.png"}')))
?>  ?=(%& -.parsed)
?>  =('https://example.com/{id}.png' (~(got by details.p.parsed) 'artworkTemplate'))
~|  %invalid-browser-artwork-pattern
=/  parsed  (parse-brand (need (de:json:html '{"artworkTemplate":"https://example.com/static.png"}')))
?>  ?=(%| -.parsed)
=/  parsed  (parse-brand (need (de:json:html '{"artworkTemplate":"javascript:{id}"}')))
?>  ?=(%| -.parsed)
~|  %branding-validation
=/  checked  (parse-brand (need (de:json:html '{"title":"Nockmilio Only","accent":"#1234ab","header":"https://example.com/image.png"}')))
?>  ?=(%& -.checked)
=/  checked  (parse-brand (need (de:json:html '{"accent":"red; color: blue"}')))
?>  ?=(%| -.checked)
=/  checked  (parse-brand (need (de:json:html '{"header":"javascript:alert(1)"}')))
?>  ?=(%| -.checked)
=/  checked  (parse-brand (need (de:json:html '{"avatar":"data:image/svg+xml,abc"}')))
?>  ?=(%| -.checked)
~|  %create-uses-exact-slug
=/  input  (need (de:json:html '{"action":"create-group","group":"nockmilio","name":"Nockmilio"}'))
=/  made  (begin *settings ~ ~nec now input)
?>  ?=(%& -.made)
?>  =(%nockmilio group:(need work.p.made))
~|  %duplicate-and-overlapping-provisioning-refused
=/  checked  (begin p.made ~ ~nec now input)
?>  ?=(%| -.checked)
=/  grp  *group-view
=/  groups  (~(put by *(map [ship @tas] group-view)) [~nec %nockmilio] grp)
=/  checked  (begin *settings groups ~nec now input)
?>  ?=(%| -.checked)
~|  %roles-require-local-hosted-group
=/  input  (need (de:json:html '{"action":"create-role","group":"nockmilio","role":"holder","name":"Holder"}'))
=/  checked  (begin *settings groups ~nec now input)
?>  ?=(%& -.checked)
=/  checked  (begin *settings groups ~zod now input)
?>  ?=(%| -.checked)
~|  %duplicate-role-refused
=.  grp  grp(roles (~(put by roles.grp) %holder [['Holder' '' '' ''] ~]))
=.  groups  (~(put by groups) [~nec %nockmilio] grp)
=/  checked  (begin *settings groups ~nec now input)
?>  ?=(%| -.checked)
~|  %public-info-excludes-host-state
=/  st  *state
=/  cfg=collection  ['Nockmilio' 8.453 0xabc %club %holder %none '' &]
=.  collections.st  (~(put by collections.st) %nockmilio cfg)
=/  info  (public-info st *settings %nockmilio)
?>  ?=([%o *] info)
?>  =((silt `(list @t)`~['id' 'name' 'brand']) ~(key by p.info))
~|  %delete-refuses-foreign-actor-and-stale-revision
=/  deletion  (need (de:json:html '{"action":"delete-collection","id":"nockmilio","revision":"0"}'))
=/  checked  (act st now ~zod ~nec deletion)
?>  ?=(%| -.checked)
=/  checked  (act st(revision 1) now ~nec ~nec deletion)
?>  ?=(%| -.checked)
~|  %delete-removes-claims-sources-and-pending-access-without-kicking
=.  tokens.st  (~(put by tokens.st) [%nockmilio 7] 0x1)
=.  claims.st  (~(put by claims.st) [%nockmilio 7] [~zod 0x1 0])
=.  applied.st  (~(put by applied.st) [%club ~zod] (silt ~[%holder]))
=.  managed.st  (silt ~[[%club ~zod]])
=.  nft-sources.st  (~(put by nft-sources.st) %nockmilio *source)
=/  removed  (act st now ~nec ~nec deletion)
?>  ?=(%& -.removed)
?>  =(~ collections.p.removed)
?>  =(~ claims.p.removed)
?>  =(~ tokens.p.removed)
?>  =(~ nft-sources.p.removed)
?>  =(~ managed.p.removed)
?>  =(~ effects:(reconcile p.removed now))
~|  %unrelated-policy-does-not-kick-retired-members
=/  other  st(collections (~(put by collections.st) %other cfg(contract 0xdef, role %another)))
=/  removed  (act other now ~nec ~nec deletion)
?>  ?=(%& -.removed)
?>  =(~ managed.p.removed)
?>  =(~ effects:(reconcile p.removed now))
~|  %shared-role-remains-managed-for-other-collection
=.  collections.st  (~(put by collections.st) %other cfg(contract 0xdef))
=.  claims.st  (~(put by claims.st) [%other 8] [~zod 0x1 0])
=/  removed  (act st now ~nec ~nec deletion)
?>  ?=(%& -.removed)
?>  (~(has by claims.p.removed) [%other 8])
?>  (~(has in (~(got by applied.p.removed) [%club ~zod])) %holder)
?>  (~(has in managed.p.removed) [%club ~zod])
~|  %remote-endpoint-cannot-create-delete-or-configure
?>  !(allowed-action %action (need (de:json:html '{"action":"create-group"}')))
?>  !(allowed-action %action deletion)
~|  %saved-brand-migration-preserves-customization
=/  old=settings-3  *settings-3
=/  brand=brand-3  ['Invite' 'Subtitle' 'Claim' 'Description' 'https://example.com/banner' 'https://example.com/pfp' '#101820' '#18232c' '#f4f2e9' '#b0b9bd' '#98c18d']
=.  old  old(brands (~(put by brands.old) %demo brand), serial 42)
=/  migrated  (migrate-settings old)
=/  brand  (~(got by brands.migrated) %demo)
?>  =('Claim' claim-title.brand)
?>  =('#101820' background.brand)
?>  =(42 serial.migrated)
?>  =(~ details.brand)
~|  %full-palette-typography-and-footer
=/  parsed  (parse-brand (need (de:json:html '{"secondary":"#123456","fontBody":"IBM Plex Sans, sans-serif","rounding":"round","spacing":"roomy","footer":"Sovereign company."}')))
?>  ?=(%& -.parsed)
?>  =('roomy' (~(got by details.p.parsed) 'spacing'))
~|  %font-and-layout-injection-refused
=/  parsed  (parse-brand (need (de:json:html '{"fontBody":"url(https://example.com)","spacing":"wild"}')))
?>  ?=(%| -.parsed)
(pure:m !>([%gater-community-tests 18 %passed]))
