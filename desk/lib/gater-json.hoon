|%
++  get
  |=  [j=json key=@t]
  ^-  json
  ?@  j  ~
  ?.  ?=(%o -.j)  ~
  (~(gut by p.j) key *json)
++  str
  |=  [j=json key=@t]
  =/  v  (get j key)
  ?@  v  ''
  ?.  ?=(%s -.v)  ''
  p.v
++  bool
  |=  [j=json key=@t default=?]
  =/  v  (get j key)
  ?@  v  default
  ?.  ?=(%b -.v)  default
  p.v
++  uint
  |=  [j=json key=@t]
  ^-  (unit @ud)
  =/  v  (get j key)
  ?@  v  ~
  ?+  -.v  ~
    %s  (rush p.v (bass 10 (plus dit)))
    %n  (rush p.v (bass 10 (plus dit)))
  ==
++  hex-number
  |=  value=@t
  ^-  (unit @ux)
  (rush value ;~(pfix (jest '0x') (bass 16 (plus hit))))
++  address
  |=  value=@t
  ^-  (unit @ux)
  ?.  =(42 (met 3 value))  ~
  =/  val  (hex-number (crip (cass (trip value))))
  ?~  val  ~
  ?.  &((gth u.val 0) (lth u.val (bex 160)))  ~
  val
++  decimal
  |=  value=@ud
  ^-  @t
  (crip (skim (trip (scot %ud value)) |=(ch=@t !=(ch '.'))))
++  hex
  |=  value=@ux
  ^-  @t
  (crip (skim (trip (scot %ux value)) |=(ch=@t !=(ch '.'))))
++  addr
  |=  value=@ux
  ^-  @t
  =/  digits  (slag 2 (trip (hex value)))
  (crip (weld "0x" (weld (reap (sub 40 (lent digits)) '0') digits)))
++  array
  |=  value=json
  ^-  (list json)
  ?@  value  ~
  ?:(?=(%a -.value) p.value ~)
--
