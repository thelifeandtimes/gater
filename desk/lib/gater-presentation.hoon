::  Public display data only. No settings buckets, credentials or ownership
::  indexes leave this adapter. Artwork is loaded and cached only by browsers.
/-  *gater
/+  j=gater-json, community=gater-community
|%
::  Legacy types only: %4/%5 migration reads and discards these fields.
+$  item  [name=@t image=@t uri=@t]
+$  cache  [tokens=(map asset item) images=(map @t @t)]
++  hosts
  |=  bowl=bowl:gall
  ^-  json
  =/  domains  .^((set turf) %e /(scot %p our.bowl)/domains/(scot %da now.bowl))
  =/  urls=(list json)
    %+  turn  ~(tap in domains)
    |=  domain=turf
    :-  %s
    (cat 3 'https://' (rap 3 (join `@t`'.' (flop domain))))
  =/  eauth  .^((unit @t) %ex /(scot %p our.bowl)//(scot %da now.bowl)/eauth/url)
  ?~  eauth  a+urls
  =/  len  (met 3 u.eauth)
  ?:  (lth len 8)  a+urls
  [%a [s+(end [3 (sub len 8)] u.eauth) urls]]
++  desk-settings
  |=  [bowl=bowl:gall desk=@tas]
  ^-  json
  ?.  .^(? %gu /(scot %p our.bowl)/settings/(scot %da now.bowl)/$)  ~
  .^(json %gx /(scot %p our.bowl)/settings/(scot %da now.bowl)/desk/[desk]/json)
++  entry
  |=  [view=json bucket=@t key=@t]
  ^-  json
  =/  value  (get:j (get:j (get:j view 'desk') bucket) key)
  ?.  ?=([%s *] value)  ~
  ?:  (gth (met 3 p.value) 262.144)  ~
  (fall (de:json:html p.value) ~)
++  appearance
  |=  bowl=bowl:gall
  ^-  json
  =/  profile  (entry (desk-settings bowl %omarchy-urbit-theme) 'appearance' 'current')
  =/  colors  ?:(=(`1 (uint:j profile 'schemaVersion')) (get:j profile 'colors') ~)
  =/  font  (str:j profile 'font')
  =?  colors  !?=([%o *] colors)
    =/  themes  (entry (desk-settings bowl %talon) 'ui-prefs' 'themes')
    =/  found
      %+  skim  (array:j (get:j themes 'themes'))
      |=(t=json =('omarchy-urbit-theme' (str:j t 'id')))
    ?~  found  ~
    =/  t  i.found
    %-  pairs:enjs:format
    :~  background+(get:j t 'background')  foreground+(get:j t 'text')
        accent+(get:j t 'primary')  surface+(get:j t 'surface')
        secondary+(get:j t 'secondary')  tertiary+(get:j t 'tertiary')
        raised+(get:j t 'raised')  muted+(get:j t 'muted')
        error+(get:j t 'error')  selection+(get:j t 'selection')  link+(get:j t 'link')
    ==
  ?.  ?=([%o *] colors)  [%o ~]
  =/  safe
    %-  pairs:enjs:format
    %+  skim  ~(tap by p.colors)
    |=  [key=@t val=json]
    &((lte (met 3 key) 40) ?=([%s *] val) (color:community p.val))
  (pairs:enjs:format ~[colors+safe font+s+?:((lte (met 3 font) 160) font '')])
--
