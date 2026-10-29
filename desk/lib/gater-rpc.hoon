::  Native, finalized JSON-RPC indexing. Credentials and resumable work stay
::  in Gall state; +status-json is the only representation sent to the browser.
/-  *gater
/+  j=gater-json, audit=gater-audit, ethereum
|%
+$  call  [method=@t params=(list json)]
+$  header  [height=@ud hash=@ux stamp=@da]
+$  options  [mode=?(%enumerable %events-supply) start=@ud review=@t]
+$  token  [owner=@ux generation=@ud]
+$  cache
  $:  point=header
      epoch=@ux
      code=@ux
      start=@ud
      tokens=(map @ud token)
      checked=@da
  ==
+$  job
  $:  kind=?(%azimuth %nft)
      col=@tas
      chain=@ud
      contract=@ux
      opts=options
      stage=@tas
      requests=(list call)
      target=header
      previous=header
      cursor=@ud
      window=$~(10.000 @ud)
      last=@ud
      supply=@ud
      code=@ux
      epoch=@ux
      bootstrap=@ud
      tokens=(map @ud token)
      changed=(set @ud)
      remaining=(list @ud)
      blocks=(list [@ud @ux])
      events=(list event:audit)
      pending=(list event:audit)
      logs=(list event:audit)
      checked=@da
      attempts=@ud
  ==
+$  store-0
  $:  infura=@t
      ethereum-url=@t
      base-url=@t
      indexes=(map @tas options)
      caches=(map @tas cache)
      audit-point=header
      audit-logs=(list event:audit)
      work=(unit job)
      queue=(list (unit @tas))
      serial=@ud
      sent=$~(| ?)
      due=@da
      errors=(map @tas @t)
  ==
+$  store
  $:  infura=@t
      ethereum-url=@t
      base-url=@t
      indexes=(map @tas options)
      caches=(map @tas cache)
      audit-point=header
      audit-logs=(list event:audit)
      work=(unit job)
      queue=(list (unit @tas))
      serial=@ud
      sent=$~(| ?)
      due=@da
      errors=(map @tas @t)
      bootstrap=(unit snapshot:audit)
      anchor=$~([25.421.988 0x8553.6022.c48f.6151.26d0.7e8f.c4ed.7ea2.d5d5.ec8d.a742.19a2.1580.ffbf.eab5.1e4b 0xe212.a820.170a.f296.9ae4.cd80.3ebe.8228.0a97.3fd8.6d27.8715.96d6.e811.7dbe.146e] [height=@ud hash=@ux digest=@ux])
  ==
++  migrate-store
  |=  old=store-0
  ^-  store
  =/  new  *store
  new(infura infura.old, ethereum-url ethereum-url.old, base-url base-url.old, indexes indexes.old, caches caches.old, audit-point audit-point.old, audit-logs audit-logs.old, work work.old, queue queue.old, serial serial.old, sent sent.old, due due.old, errors errors.old)
++  bootstrap-info
  |=  [s=store b=bowl:gall]
  ^-  json
  =/  result  (mule |.((snapshot-now:audit b)))
  =/  current=json
    ?-  -.result
      %|  ~
      %&  (pairs:enjs:format ~[height+s+(decimal:j number.id.p.result) hash+s+(hex-width:audit hash.id.p.result 32) digest+s+(hex-width:audit (shax (jam p.result)) 32)])
    ==
  (pairs:enjs:format ~[current+current height+s+(decimal:j height.anchor.s) hash+s+(hex-width:audit hash.anchor.s 32) digest+s+(hex-width:audit digest.anchor.s 32) retained+b+?=(^ bootstrap.s)])
++  anchor-height  25.421.988
++  anchor-hash  0x8553.6022.c48f.6151.26d0.7e8f.c4ed.7ea2.d5d5.ec8d.a742.19a2.1580.ffbf.eab5.1e4b
++  anchor-digest  0xe212.a820.170a.f296.9ae4.cd80.3ebe.8228.0a97.3fd8.6d27.8715.96d6.e811.7dbe.146e
++  azimuth-address  0x223c.067f.8cf2.8ae1.73ee.5caf.ea60.ca44.c335.fecb
++  rollup-address  0xeb70.029c.fb3c.53c7.78ea.f68c.d28d.e725.390a.1fe9
++  transfer  0xddf2.52ad.1be2.c89b.69c2.b068.fc37.8daa.952b.a7f1.63c4.a116.28f5.5a4d.f523.b3ef
++  consecutive  0xdeaa.91b6.123d.068f.5821.d0fb.0678.463d.1a8a.6079.fe8a.f5de.3ce5.e896.dcf9.133d
++  default-options
  |=  c=collection
  ^-  options
  ?:  &(=(chain.c 8.453) =(contract.c 0x7465.e492.a183.f16c.0805.e572.6289.8c7b.ec11.808a))
    [%events-supply 52.544.634 'Reviewed Nockmilio ERC721A mint/transfer/burn history; see docs/nockmilio-verification.md.']
  [%enumerable 0 '']
++  parse-options
  |=  [input=json fallback=options]
  ^-  (each options @t)
  ?:  ?=(~ input)  [%& fallback]
  =/  mode  (str:j input 'mode')
  ?.  ?=(?(%enumerable %events-supply) mode)  [%| 'Choose enumeration or reviewed event history.']
  =/  start  (uint:j input 'start')
  =/  review  (str:j input 'review')
  ?:  &(=(mode %events-supply) |(?~(start & =(u.start 0)) =(review '') (gth (met 3 review) 2.048)))
    [%| 'Event indexing needs the deployment block and a description of the reviewed mint, transfer and burn coverage.']
  [%& mode ?~(start 0 u.start) review]
++  safe-url
  |=  url=@t
  ^-  ?
  ?:  =(url '')  &
  &((lte (met 3 url) 2.048) =('https://' (crip (scag 8 (trip url)))) (gth (met 3 url) 8) (levy (trip url) |=(ch=@t &((gte ch 33) (lte ch 126) !=(ch '#')))))
++  configure
  |=  [saved=store input=json now=@da]
  ^-  (each store @t)
  =/  key  (str:j input 'infuraKey')
  =/  eth  (str:j input 'ethereumUrl')
  =/  base  (str:j input 'baseUrl')
  ?.  &((lte (met 3 key) 128) (levy (trip key) |=(c=@t |(&((gte c 'a') (lte c 'z')) &((gte c 'A') (lte c 'Z')) &((gte c '0') (lte c '9')) =(c '-') =(c '_')))) (safe-url eth) (safe-url base))
    [%| 'Use an alphanumeric Infura API key or a valid HTTPS RPC endpoint.']
  =?  infura.saved  !=(key '')  key
  =?  ethereum-url.saved  !=(eth '')  eth
  =?  base-url.saved  !=(base '')  base
  =?  infura.saved  (bool:j input 'clearInfura' |)  ''
  =?  ethereum-url.saved  (bool:j input 'clearEthereum' |)  ''
  =?  base-url.saved  (bool:j input 'clearBase' |)  ''
  ::  An old provider's in-flight response cannot enter the new run.
  [%& saved(work ~, queue ~, sent |, serial +(serial.saved), due now, errors ~)]
++  endpoint
  |=  [s=store chain=@ud]
  ^-  @t
  =/  custom  ?:(=(chain 1) ethereum-url.s base-url.s)
  ?:  !=(custom '')  custom
  ?:  =(infura.s '')  ''
  (cat 3 ?:(=(chain 1) 'https://mainnet.infura.io/v3/' 'https://base-mainnet.infura.io/v3/') infura.s)
++  number-hex
  |=  n=@
  (hex:j `@ux`n)
++  quantity
  |=  value=json
  ^-  @
  ?>  ?=([%s *] value)
  (need (hex-number:j p.value))
++  field-number
  |=  [value=json key=@t]
  (quantity (get:j value key))
++  parse-header
  |=  value=json
  ^-  header
  =/  hash  (field-number value 'hash')
  ?>  &((gth hash 0) (lth hash (bex 256)))
  [(field-number value 'number') hash (add ~1970.1.1 (mul (field-number value 'timestamp') ~s1))]
++  fresh-header
  |=  [h=header now=@da]
  &((lte stamp.h now) (lte (sub now stamp.h) ~h1))
++  block-call
  |=  name=@t
  ^-  call
  ['eth_getBlockByNumber' ~[s+name b+|]]
++  word
  |=  n=@
  (hex-width:audit `@ux`n 32)
++  contract-call
  |=  [w=job data=@t]
  ^-  call
  ['eth_call' ~[(pairs:enjs:format ~[to+s+(addr:j contract.w) data+s+data]) s+(number-hex height.target.w)]]
++  abi-call
  |=  [w=job selector=@t arg=@ud]
  (contract-call w (cat 3 selector (crip (slag 2 (trip (word arg))))))
++  code-call
  |=  [w=job height=@ud]
  ^-  call
  ['eth_getCode' ~[s+(addr:j contract.w) s+(number-hex height)]]
++  code-hash
  |=  value=json
  ^-  @ux
  ?>  ?=([%s *] value)
  ?>  &((gth (met 3 p.value) 2) =(0 (mod (met 3 p.value) 2)))
  =/  valid  (quantity value)
  ::  Match the v0.1 worker's SHA256 of lowercase ASCII bytecode.
  (swp 3 (shax (crip (cass (trip p.value)))))
++  envelope
  |=  [requests=(list call) nonce=@ud]
  ^-  json
  :-  %a
  =/  index  0
  |-
  ?~  requests  ~
  :-  (pairs:enjs:format ~[jsonrpc+s+'2.0' id+s+(cat 3 (decimal:j nonce) (cat 3 ':' (decimal:j index))) method+s+method.i.requests params+a+params.i.requests])
  $(requests t.requests, index +(index))
++  provider-error
  |=  value=json
  ^-  (unit @t)
  =/  rows=(list json)  ?:(?=([%a *] value) p.value ~[value])
  |-
  ?~  rows  ~
  =/  err  (get:j i.rows 'error')
  ?~  err  $(rows t.rows)
  =/  code  (get:j err 'code')
  ?.  ?=([%n *] code)  `'RPC provider rejected the batch. Check endpoint capabilities and account limits.'
  ?:  |(=('-32005' p.code) =('-32016' p.code) =('429' p.code))
    `'RPC provider rate or query limit reached. Retrying with bounded backoff.'
  ?:  =('-32601' p.code)  `'RPC provider does not support a required method.'
  ?:  =('-32602' p.code)  `'RPC provider rejected the request parameters or historical block.'
  `'RPC provider rejected the batch. Check endpoint capabilities and account limits.'
++  results
  |=  [requests=(list call) nonce=@ud value=json]
  ^-  (list json)
  ?>  ?=([%a *] value)
  ?>  =((lent requests) (lent p.value))
  =/  found=(map @t json)  ~
  =.  found
    %+  roll  p.value
    |=  [row=json found=_found]
    ?>  &(?=([%o *] row) =('2.0' (str:j row 'jsonrpc')))
    =/  id  (str:j row 'id')
    ?>  &(!=(id '') !(~(has by found) id) !(~(has by p.row) 'error') (~(has by p.row) 'result'))
    (~(put by found) id (get:j row 'result'))
  %+  turn  (gulf 0 (dec (lent requests)))
  |=  index=@ud
  (~(got by found) (cat 3 (decimal:j nonce) (cat 3 ':' (decimal:j index))))
++  log-request
  |=  w=job
  ^-  job
  =.  last.w  (min height.target.w (add cursor.w (dec window.w)))
  =/  addr=json
    ?:  =(kind.w %nft)  s+(addr:j contract.w)
    a+~[s+(addr:j azimuth-address) s+(addr:j rollup-address)]
  =/  filter  (pairs:enjs:format ~[address+addr 'fromBlock'^s+(number-hex cursor.w) 'toBlock'^s+(number-hex last.w)])
  =?  filter  =(kind.w %nft)
    ?>  ?=([%o *] filter)
    [%o (~(put by p.filter) 'topics' a+~[a+~[s+(word transfer) s+(word consecutive)]])]
  w(stage %logs, requests ~[['eth_getLogs' ~[filter]]])
++  owner-requests
  |=  w=job
  ^-  job
  ?:  ?=(~ remaining.w)
    w(stage %finish, requests ~[(block-call (number-hex height.target.w))])
  w(stage %owners, requests (turn (scag 5 ^-((list @ud) remaining.w)) |=(id=@ud (abi-call w '0x6352211e' id))))
++  enumeration-requests
  |=  w=job
  ^-  job
  ?:  ?=(~ remaining.w)
    (owner-requests w(remaining (sort ~(tap in changed.w) lth)))
  w(stage %enumerate, requests (turn (scag 5 ^-((list @ud) remaining.w)) |=(id=@ud (abi-call w '0x4f6ccce7' id))))
++  finish-logs
  |=  w=job
  ^-  job
  ?:  (lte cursor.w height.target.w)  (log-request w)
  ?:  =(kind.w %azimuth)
    w(stage %finish, requests ~[(block-call (number-hex height.target.w))])
  ?>  =(supply.w ~(wyt by tokens.w))
  (owner-requests w(remaining (sort (skim ~(tap in changed.w) |=(id=@ud (~(has by tokens.w) id))) lth)))
++  block-requests
  |=  w=job
  ^-  job
  ?:  ?=(^ blocks.w)
    w(stage %blocks, requests (turn (scag 5 ^-((list [@ud @ux]) blocks.w)) |=([number=@ud hash=@ux] (block-call (number-hex number)))))
  ?:  =(kind.w %azimuth)
    =.  pending.w  (skim events.w |=(e=event:audit =(address.e rollup-address)))
    ?:  ?=(^ pending.w)
      w(stage %inputs, requests (turn (scag 5 ^-((list event:audit) pending.w)) |=(e=event:audit ['eth_getTransactionByHash' ~[s+(word transaction-hash:(need mined.e))]])))
    (finish-logs w(logs (weld logs.w events.w), cursor +(last.w), events ~))
  (finish-logs w(cursor +(last.w), events ~))
++  start
  |=  [s=store st=state col=(unit @tas) now=@da]
  ^-  job
  =/  w=job  *job
  ?~  col
    %=  w
      kind  %azimuth
      chain  1
      stage  %chain
      requests  ~[['eth_chainId' ~]]
      previous  ?:(=(0 height.audit-point.s) [height.anchor.s hash.anchor.s ~2000.1.1] audit-point.s)
      cursor  +(?:(=(0 height.audit-point.s) height.anchor.s height.audit-point.s))
      logs  audit-logs.s
    ==
  =/  c  (~(got by collections.st) u.col)
  =.  w  w(kind %nft, col u.col, chain chain.c, contract contract.c, opts (~(gut by indexes.s) u.col (default-options c)), stage %chain, requests ~[['eth_chainId' ~]], epoch (shax (jam [now u.col])))
  =/  old  (~(get by caches.s) u.col)
  ?~  old
    ::  Preserve released-version claims by carrying its verified cursor and
    ::  generations forward, then independently checking all current owners.
    =/  cp  (~(get by checkpoints.st) u.col)
    =/  src  (~(get by nft-sources.st) u.col)
    ?:  |(?=(~ cp) ?=(~ src))  w(cursor start.opts.w, bootstrap start.opts.w)
    ?>  ?=(^ cp)
    ?>  ?=(^ src)
    ?>  =(mode.opts.w method.u.src)
    ?>  |(=(mode.opts.w %enumerable) =(start.opts.w start.u.src))
    =.  tokens.w
      %-  ~(gas by *(map @ud token))
      %+  murn  ~(tap by tokens.st)
      |=  [key=asset owner=@ux]
      ?.  =(collection.key u.col)  ~
      `[token.key owner (~(got by token-generations.st) key)]
    w(previous [height.u.cp hash.u.cp ~2000.1.1], cursor +(height.u.cp), code code-hash.u.src, epoch epoch.u.src, bootstrap start.u.src, changed (silt (turn ~(tap by tokens.w) head)))
  =/  old  u.old
  %=  w
    previous  point.old
    cursor  +(height.point.old)
    epoch  epoch.old
    code  code.old
    bootstrap  start.old
    tokens  tokens.old
    checked  checked.old
    changed  ?:(|((gth now (add checked.old ~h6)) (lth now checked.old)) (silt (turn ~(tap by tokens.old) head)) ~)
  ==
++  parse-log
  |=  row=json
  ^-  event:audit
  ?>  =(b+| (get:j row 'removed'))
  ?>  =(66 (met 3 (str:j row 'blockHash')))
  ?>  =(66 (met 3 (str:j row 'transactionHash')))
  ?>  =(42 (met 3 (str:j row 'address')))
  =/  data  (str:j row 'data')
  ?>  &((gte (met 3 data) 2) =(0 (mod (met 3 data) 2)))
  ?>  |(=(data '0x') ?=(^ (hex-number:j data)))
  =/  topics  (array:j (get:j row 'topics'))
  ?>  &((gth (lent topics) 0) (lte (lent topics) 4))
  ?>  (levy topics |=(value=json &(?=([%s *] value) =(66 (met 3 p.value)))))
  (parse-event-log:rpc:ethereum row)
++  event-order
  |=  [a=event:audit b=event:audit]
  =/  am  (need mined.a)
  =/  bm  (need mined.b)
  ?:(=(block-number.am block-number.bm) (lth log-index.am log-index.bm) (lth block-number.am block-number.bm))
++  apply-transfer
  |=  [w=job e=event:audit]
  ^-  job
  =/  m  (need mined.e)
  =/  topics=(list @ux)  topics.e
  ?>  =(4 (lent topics))
  =/  signature  i.topics.e
  =/  start=@ud  `@ud`?:(=(signature transfer) (snag 3 topics) (snag 1 topics))
  =/  end=@ud  `@ud`?:(=(signature transfer) start (need (hex-number:j data.e)))
  =/  from  (snag ?:(=(signature transfer) 1 2) topics)
  =/  to  (snag ?:(=(signature transfer) 2 3) topics)
  ?>  &(|(=(signature transfer) =(signature consecutive)) (lte start end) (lte (sub end start) 100.000) (lth from (bex 160)) (lth to (bex 160)) |(=(signature consecutive) =(data.e '0x')))
  |-
  ?:  (gth start end)  w
  =/  old  (~(get by tokens.w) start)
  ?>  ?:  =(from 0)  ?=(~ old)
      ?~  old  |
      =(owner.u.old from)
  =?  changed.w  !=(from to)  (~(put in changed.w) start)
  =.  tokens.w
    ?:  =(to 0)  (~(del by tokens.w) start)
    (~(put by tokens.w) start [to ?~(old (shax (jam [block-hash.m log-index.m start])) ?:(=(from to) generation.u.old (shax (jam [block-hash.m log-index.m start]))))])
  ?>  (lte ~(wyt by tokens.w) 100.000)
  $(start +(start))
++  advance
  |=  [w=job replies=(list json) now=@da]
  ^-  job
  ?>  =((lent replies) (lent requests.w))
  =.  attempts.w  0
  ?+  stage.w  !!
    %chain
      ?>  =((quantity (snag 0 replies)) chain.w)
      w(stage %head, requests ~[(block-call 'finalized')])
    %head
      =/  h  (parse-header (snag 0 replies))
      ?>  &((fresh-header h now) (gte height.h height.previous.w))
      =.  target.w  h
      ?:  !=(0 height.previous.w)
        w(stage %checkpoint, requests ~[(block-call (number-hex height.previous.w))])
      ?>  =(kind.w %nft)
      w(stage %code, requests ~[(code-call w height.h)])
    %checkpoint
      =/  h  (parse-header (snag 0 replies))
      ?>  =([height.h hash.h] [height.previous.w hash.previous.w])
      ?:  =(kind.w %azimuth)  (finish-logs w)
      w(stage %code, requests ~[(code-call w height.target.w)])
    %code
      =/  code  (code-hash (snag 0 replies))
      ?>  |(=(code.w 0) =(code.w code))
      =.  code.w  code
      ?:  &(=(mode.opts.w %events-supply) =(0 height.previous.w))
        ?>  &((gth start.opts.w 0) (lte start.opts.w height.target.w))
        w(stage %deployment, requests ~[(code-call w (dec start.opts.w)) (code-call w start.opts.w)])
      w(stage %supply, requests ~[(abi-call w '0x01ffc9a7' (lsh [3 28] 0x80ac.58cd)) (contract-call w '0x18160ddd')])
    %deployment
      ?>  =([%s '0x'] (snag 0 replies))
      =/  valid  (code-hash (snag 1 replies))
      w(stage %supply, requests ~[(abi-call w '0x01ffc9a7' (lsh [3 28] 0x80ac.58cd)) (contract-call w '0x18160ddd')])
    %supply
      ?>  =(1 (quantity (snag 0 replies)))
      =.  supply.w  (quantity (snag 1 replies))
      ?>  (lte supply.w 100.000)
      ?:  &(=(0 height.previous.w) =(mode.opts.w %enumerable))
        w(stage %enumerable, bootstrap height.target.w, requests ~[(abi-call w '0x01ffc9a7' (lsh [3 28] 0x780e.9d63))])
      (finish-logs w)
    %enumerable
      ?>  =(1 (quantity (snag 0 replies)))
      (enumeration-requests w(remaining ?:(=(0 supply.w) ~ (gulf 0 (dec supply.w)))))
    %enumerate
      =/  w=job  w
      =.  w
        %+  roll  replies
        |=  [value=json w=_w]
        =/  id=@ud  (quantity value)
        ?>  !(~(has by tokens.w) id)
        w(tokens (~(put by tokens.w) id ^-(token [0x0 (shax (jam [hash.target.w id]))])), changed (~(put in changed.w) id))
      (enumeration-requests w(remaining (slag (lent replies) remaining.w)))
    %logs
      =/  w=job  w
      =/  value  (snag 0 replies)
      ?>  ?=([%a *] value)
      ?>  (lte (lent p.value) 100.000)
      =/  events  (sort (turn p.value parse-log) event-order)
      =/  seen=(set [@ud @ud])  ~
      =/  hashes=(map @ud @ux)  ~
      =.  w
        %+  roll  events
        |=  [e=event:audit w=_w]
        =/  m  (need mined.e)
        ?>  &(!removed.m (gte block-number.m cursor.w) (lte block-number.m last.w) (gth block-hash.m 0) (lth block-hash.m (bex 256)))
        ?>  ?:  =(kind.w %nft)  =(address.e contract.w)
            |(=(address.e azimuth-address) =(address.e rollup-address))
        ?:(=(kind.w %nft) (apply-transfer w e) w)
      =/  unique
        %+  roll  events
        |=  [e=event:audit out=[seen=_seen hashes=_hashes]]
        =/  m  (need mined.e)
        ?>  !(~(has in seen.out) [block-number.m log-index.m])
        =/  previous  (~(get by hashes.out) block-number.m)
        ?>  ?~(previous & =(u.previous block-hash.m))
        [(~(put in seen.out) [block-number.m log-index.m]) (~(put by hashes.out) block-number.m block-hash.m)]
      (block-requests w(events events, blocks ~(tap by hashes.unique)))
    %blocks
      =.  blocks.w
        =/  blocks  blocks.w
        |-
        ?~  replies  blocks
        ?>  ?=(^ blocks)
        =/  h  (parse-header i.replies)
        ?>  =([height.h hash.h] i.blocks)
        $(replies t.replies, blocks t.blocks)
      (block-requests w)
    %inputs
      =/  inputs=(map @ux @ux)
        =/  pending  pending.w
        =|  out=(map @ux @ux)
        |-
        ?~  replies  out
        ?>  ?=(^ pending)
        =/  m  (need mined.i.pending)
        =/  r  i.replies
        ?>  ?&  =((field-number r 'hash') transaction-hash.m)
                =((field-number r 'blockHash') block-hash.m)
                =((field-number r 'blockNumber') block-number.m)
                =((field-number r 'to') rollup-address)
            ==
        $(pending t.pending, replies t.replies, out (~(put by out) transaction-hash.m (field-number r 'input')))
      =.  events.w
        %+  turn  events.w
        |=  e=event:audit
        =/  m  (need mined.e)
        =/  input  (~(get by inputs) transaction-hash.m)
        ?~  input  e
        e(mined `m(input input))
      =.  pending.w  (slag (lent replies) pending.w)
      ?:  ?=(^ pending.w)
        w(requests (turn (scag 5 ^-((list event:audit) pending.w)) |=(e=event:audit ['eth_getTransactionByHash' ~[s+(word transaction-hash:(need mined.e))]])))
      (finish-logs w(logs (weld logs.w events.w), cursor +(last.w), events ~))
    %owners
      =/  w=job  w
      =.  w
        %+  roll  replies
        |=  [value=json w=_w]
        ?>  ?=(^ remaining.w)
        =/  id  i.remaining.w
        =/  owner  (quantity value)
        ?>  &((gth owner 0) (lth owner (bex 160)))
        =/  old  (~(got by tokens.w) id)
        ?>  |(=(owner.old 0) =(owner.old owner))
        w(tokens (~(put by tokens.w) id old(owner owner)), remaining t.remaining.w)
      (owner-requests w)
    %finish
      ?>  =((parse-header (snag 0 replies)) target.w)
      ::  A large bootstrap can outlive its target's freshness. Preserve the
      ::  verified prefix, acquire newer finality and replay the gap before
      ::  committing. No partial state or stale header is exposed to policy.
      ?.  (fresh-header target.w now)
        ?>  (lte stamp.target.w now)
        w(stage %head, previous target.w, cursor +(height.target.w), changed ~, requests ~[(block-call 'finalized')])
      w(stage %done, requests ~)
  ==
++  snapshot-json
  |=  [w=job now=@da]
  ^-  json
  (pairs:enjs:format ~[action+s+'snapshot' collection+s+col.w chain+s+(decimal:j chain.w) contract+s+(addr:j contract.w) block+s+(decimal:j height.target.w) 'blockHash'^s+(word hash.target.w) 'observedAt'^s+(decimal:j (div (sub now ~1970.1.1) ~s1)) epoch+s+(word epoch.w) coverage+(pairs:enjs:format ~[method+s+mode.opts.w 'fromBlock'^s+(decimal:j bootstrap.w) supply+s+(decimal:j supply.w) 'codeHash'^s+(word code.w)]) tokens+a+(turn ~(tap by tokens.w) |=([id=@ud tok=token] (pairs:enjs:format ~[id+s+(decimal:j id) owner+s+(addr:j owner.tok) generation+s+(decimal:j generation.tok)])))])
++  status-json
  |=  s=store
  ^-  json
  %-  pairs:enjs:format
  :~  'infuraConfigured'^b+!=(infura.s '')
      'ethereumConfigured'^b+!=((endpoint s 1) '')
      'baseConfigured'^b+!=((endpoint s 8.453) '')
      'ethereumCustom'^b+!=(ethereum-url.s '')
      'baseCustom'^b+!=(base-url.s '')
      progress+?~(work.s ~ (pairs:enjs:format ~[collection+s+?:(=(kind.u.work.s %azimuth) 'azimuth' col.u.work.s) stage+s+stage.u.work.s block+s+(decimal:j cursor.u.work.s) target+s+(decimal:j height.target.u.work.s) remaining+s+(decimal:j (lent remaining.u.work.s)) supply+s+(decimal:j supply.u.work.s)]))
      errors+a+(turn ~(tap by errors.s) |=([id=@tas error=@t] (pairs:enjs:format ~[collection+s+id message+s+error])))
      indexes+a+(turn ~(tap by indexes.s) |=([id=@tas opt=options] (pairs:enjs:format ~[id+s+id mode+s+mode.opt start+s+(decimal:j start.opt) review+s+review.opt])))
  ==
--
