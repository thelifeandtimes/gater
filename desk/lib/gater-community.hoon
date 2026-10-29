::  Host-managed presentation and explicit Tlon provisioning. No membership
::  delivery is enabled here. Commands always target groups hosted by our ship.
/-  *gater
/+  j=gater-json, tlon=gater-tlon
|%
+$  brand-3
  $:  title=@t
      subtitle=@t
      claim-title=@t
      claim-subtitle=@t
      header=@t
      avatar=@t
      background=$~('#f6f5ee' @t)
      surface=$~('#ffffff' @t)
      text=$~('#202c23' @t)
      muted=$~('#63705f' @t)
      accent=$~('#27633d' @t)
  ==
+$  brand
  $:  title=@t  subtitle=@t  claim-title=@t  claim-subtitle=@t  header=@t  avatar=@t
      background=$~('#f6f5ee' @t)  surface=$~('#ffffff' @t)
      text=$~('#202c23' @t)  muted=$~('#63705f' @t)  accent=$~('#27633d' @t)
      details=(map @t @t)
  ==
+$  settings-3  [brands=(map @tas brand-3) serial=@ud work=(unit job)]
++  migrate-settings
  |=  old=settings-3
  ^-  settings
  :+  %-  ~(run by brands.old)
      |=  b=brand-3
      [title.b subtitle.b claim-title.b claim-subtitle.b header.b avatar.b background.b surface.b text.b muted.b accent.b ~]
    serial.old
  work.old
+$  job
  $:  id=@ud
      kind=?(%group %role)
      group=@tas
      role=@tas
      title=@t
      phase=?(%group %channel %role %confirm %done %failed)
      at=@da
      error=@t
  ==
+$  settings  [brands=(map @tas brand) serial=@ud work=(unit job)]
+$  groups  (map [ship @tas] group-view:tlon)
+$  card  card:agent:gall
++  valid-id
  |=  id=@t
  ^-  ?
  ?&  (lte (met 3 id) 64)
      ?=(^ (slaw %tas id))
      !?=(?(%config %claim %me %action %wallet-challenge %info %images %appearance %metadata) id)
  ==
++  color
  |=  val=@t
  ^-  ?
  &(=(7 (met 3 val)) =('#' (end [3 1] val)) ?=(^ (rush (crip (cass (slag 1 (trip val)))) (bass 16 (plus hit)))))
++  image-url
  |=  val=@t
  ^-  ?
  ?:  =(val '')  &
  ?&  (lte (met 3 val) 2.048)
      |(=('https://' (end [3 8] val)) =('http://' (end [3 7] val)))
      ?=(^ (de-purl:html val))
      !(lien (trip val) |=(ch=@t (lth ch 32)))
  ==
++  parse-brand
  |=  input=json
  ^-  (each brand @t)
  =/  b=brand  *brand
  =.  b  b(title (str:j input 'title'), subtitle (str:j input 'subtitle'), header (str:j input 'header'), avatar (str:j input 'avatar'))
  =.  b  b(claim-title (str:j input 'claimTitle'), claim-subtitle (str:j input 'claimSubtitle'))
  ?.  &((lte (met 3 claim-title.b) 160) (lte (met 3 claim-subtitle.b) 2.048))  [%| 'Claim page copy is too long.']
  ?.  &((lte (met 3 title.b) 160) (lte (met 3 subtitle.b) 2.048))
    [%| 'Keep the heading under 160 bytes and description under 2048 bytes.']
  ?.  &((image-url header.b) (image-url avatar.b))
    [%| 'Images must use an absolute HTTP or HTTPS URL (up to 2048 bytes).']
  =/  colors=(list @t)  ~['background' 'surface' 'text' 'muted' 'accent']
  ?.  (levy colors |=(key=@t |(=('' (str:j input key)) (color (str:j input key)))))
    [%| 'Palette colors must be six-digit hex values such as #27633d.']
  =.  background.b  ?:(=('' (str:j input 'background')) background.b (str:j input 'background'))
  =.  surface.b  ?:(=('' (str:j input 'surface')) surface.b (str:j input 'surface'))
  =.  text.b  ?:(=('' (str:j input 'text')) text.b (str:j input 'text'))
  =.  muted.b  ?:(=('' (str:j input 'muted')) muted.b (str:j input 'muted'))
  =.  accent.b  ?:(=('' (str:j input 'accent')) accent.b (str:j input 'accent'))
  =/  keys=(list @t)
    ~['secondary' 'tertiary' 'raised' 'error' 'selection' 'link' 'border' 'palette' 'fontDisplay' 'fontBody' 'fontMono' 'fontDisplayURL' 'fontBodyURL' 'fontMonoURL' 'spacing' 'rounding' 'footer' 'artworkTemplate' 'themeMode']
  =/  extra=(each (map @t @t) @t)
    =|  out=(map @t @t)
    |-
    ?~  keys  [%& out]
    =/  key  i.keys
    =/  val  (str:j input key)
    ?:  =(val '')  $(keys t.keys)
    ?.  (lte (met 3 val) 16.384)  [%| 'Appearance value is too long.']
    ?:  &((lien `(list @t)`~['secondary' 'tertiary' 'raised' 'error' 'selection' 'link' 'border'] |=(k=@t =(k key))) !(color val))
      [%| 'Use six-digit hex palette colors.']
    ?:  &((lien `(list @t)`~['fontDisplay' 'fontBody' 'fontMono'] |=(k=@t =(k key))) |((gth (met 3 val) 160) !(levy (trip val) |=(ch=@t |(&((gte ch 'a') (lte ch 'z')) &((gte ch 'A') (lte ch 'Z')) &((gte ch '0') (lte ch '9')) =(ch ' ') =(ch '-') =(ch ','))))))
      [%| 'Font families may contain letters, numbers, spaces, commas and hyphens.']
    ?:  &((lien `(list @t)`~['fontDisplayURL' 'fontBodyURL' 'fontMonoURL'] |=(k=@t =(k key))) !(image-url val))
      [%| 'Font files require an absolute HTTP or HTTPS URL.']
    ?:  &(=(key 'themeMode') !?=(?(%host %custom) val))
      [%| 'Choose the synced host theme or a custom palette.']
    ?:  &(=(key 'spacing') !(lien `(list @t)`~['compact' 'comfortable' 'roomy'] |=(k=@t =(k val))))
      [%| 'Choose a supported spacing preset.']
    ?:  &(=(key 'rounding') !(lien `(list @t)`~['square' 'soft' 'round'] |=(k=@t =(k val))))
      [%| 'Choose a supported rounding preset.']
    ?:  &(=(key 'footer') (gth (met 3 val) 512))  [%| 'Keep the footer under 512 bytes.']
    ?:  &(=(key 'artworkTemplate') |((gth (met 3 val) 2.048) !=('https://' (end [3 8] val)) !(image-url (crip (turn (trip val) |=(ch=@t ?:(|(=(ch '{') =(ch '}')) 'x' ch))))) ?=(~ (find (trip '{id}') (trip val)))))
      [%| 'Use an HTTPS artwork URL containing {id} for the token number.']
    ?:  &(=(key 'palette') ?=(~ (de:json:html val)))  [%| 'Import a valid JSON palette or appearance profile.']
    $(keys t.keys, out (~(put by out) key val))
  ?-  -.extra
    %|  extra
    %&  [%& b(details p.extra)]
  ==
++  brand-json
  |=  b=brand
  ^-  json
  %-  pairs:enjs:format
  %+  weld
    (turn ~(tap by details.b) |=([key=@t val=@t] [key ^-([%s @t] s+val)]))
  ^-  (list [@t json])
  :~  title+s+title.b  subtitle+s+subtitle.b
      'claimTitle'^s+claim-title.b  'claimSubtitle'^s+claim-subtitle.b  header+s+header.b
      avatar+s+avatar.b  background+s+background.b  surface+s+surface.b
      text+s+text.b  muted+s+muted.b  accent+s+accent.b
  ==
++  registry
  |=  bowl=bowl:gall
  ^-  groups
  ?.  .^(? %gu /(scot %p our.bowl)/groups/(scot %da now.bowl)/$)  ~
  .^(groups %gx /(scot %p our.bowl)/groups/(scot %da now.bowl)/v3/groups/noun)
++  hosted-json
  |=  [all=groups host=ship]
  ^-  json
  :-  %a
  %+  murn  ~(tap by all)
  |=  [[who=ship id=@tas] g=group-view:tlon]
  ?.  =(who host)  ~
  =/  meta  ;;([title=@t description=@t image=@t cover=@t] meta.g)
  =/  roles=json
    :-  %a
    %+  murn  ~(tap by roles.g)
    |=  [id=@tas value=*]
    ?:  (~(has in admins.g) id)  ~
    =/  role  ;;([meta=[title=@t description=@t image=@t cover=@t] ~] value)
    `(pairs:enjs:format ~[id+s+id name+s+title.meta.role])
  `(pairs:enjs:format ~[id+s+id name+s+title.meta roles+roles])
++  public-info
  |=  [st=state cfg=settings id=@tas]
  ^-  json
  =/  col  (~(got by collections.st) id)
  (pairs:enjs:format ~[id+s+id name+s+name.col brand+(brand-json (~(gut by brands.cfg) id *brand))])
++  decorate
  |=  [view=json cfg=settings all=groups host=ship]
  ^-  json
  ?>  ?=([%o *] view)
  =/  cols
    %+  turn  (array:j (get:j view 'collections'))
    |=  col=json
    ?>  ?=([%o *] col)
    =/  id  (str:j col 'id')
    col(p (~(put by p.col) 'brand' (brand-json (~(gut by brands.cfg) id *brand))))
  =.  p.view  (~(put by p.view) 'collections' a+cols)
  =.  p.view  (~(put by p.view) 'groups' (hosted-json all host))
  =.  p.view  (~(put by p.view) 'provisioning' (job-json work.cfg))
  =.  p.view  (~(put by p.view) 'deliveryMode' s+'preview')
  view
++  job-json
  |=  work=(unit job)
  ^-  json
  ?~  work  ~
  =/  w  u.work
  (pairs:enjs:format ~[id+s+(decimal:j id.w) kind+s+kind.w group+s+group.w role+s+role.w phase+s+phase.w error+s+error.w])
++  begin
  |=  [cfg=settings all=groups host=ship now=@da input=json]
  ^-  (each settings @t)
  ?:  ?~(work.cfg | !?=(?(%done %failed) phase.u.work.cfg))
    [%| 'A group or role is still being created. Wait for it to finish.']
  =/  kind  ?:(=('create-group' (str:j input 'action')) %group %role)
  =/  group  (str:j input 'group')
  ?.  (valid-id group)  [%| 'Use a collection/group ID of up to 64 lowercase letters, digits and hyphens.']
  =/  existing  (~(get by all) [host group])
  ?:  &(=(kind %group) ?=(^ existing))  [%| 'A group with this collection ID already exists on this host. Select it instead.']
  ?:  &(=(kind %role) ?=(~ existing))  [%| 'Choose a group hosted by this ship.']
  =/  role  (str:j input 'role')
  ?:  &(=(kind %role) |(!(valid-id role) =(role %admin)))  [%| 'Choose a non-admin role ID.']
  ?:  &(=(kind %role) ?~(existing | (~(has by roles.u.existing) role)))
    [%| 'That role already exists. Select it instead.']
  =/  title  (str:j input 'name')
  ?.  &((gth (met 3 title) 0) (lte (met 3 title) 160))  [%| 'Provide a display name of up to 160 bytes.']
  =/  serial  +(serial.cfg)
  [%& cfg(serial serial, work `[serial kind group role title kind now ''])]
++  command
  |=  [w=job host=ship]
  ^-  card
  =/  wire  /community/(scot %ud id.w)/[phase.w]
  ?-  phase.w
    %group
      [%pass wire %agent [host %groups] %poke %group-command !>([%create [group.w [title.w '' '' ''] %private [~ ~] ~]])]
    %role
      [%pass wire %agent [host %groups] %poke %group-action-5 !>([%group [host group.w] %role (silt ~[role.w]) %add [title.w '' '' '']])]
    %channel
      =/  name=@tas  (cat 3 group.w '-chat')
      [%pass wire %agent [host %channels] %poke %channel-action-1 !>([%create %chat name [host group.w] name '' ~ ~ ~])]
    *  !!
  ==
++  confirm
  |=  [cfg=settings all=groups host=ship now=@da]
  ^-  settings
  ?~  work.cfg  cfg
  =/  w  u.work.cfg
  ?:  ?=(?(%done %failed) phase.w)  cfg
  =/  group  (~(get by all) [host group.w])
  =/  done
    ?~  group  |
    ?:  =(kind.w %role)  (~(has by roles.u.group) role.w)
    (~(has by channels.u.group) [%chat host (cat 3 group.w '-chat')])
  ?:  &(=(phase.w %confirm) done)  cfg(work `w(phase %done))
  ?:  (gth now (add at.w ~m1))
    cfg(work `w(phase %failed, error 'Tlon has not confirmed the result. Inspect the group before retrying; a partial group may exist.'))
  cfg
--
