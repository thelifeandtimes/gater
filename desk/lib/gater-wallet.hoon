/-  *gater
/+  j=gater-json, policy=gater-policy
|%
++  message
  |=  [st=state now=@da who=ship host=ship key=asset expected=@ud expires=@ud]
  ^-  (each @t @t)
  ?.  =(expected revision.st)  [%| 'State changed. Refresh and request a new signature.']
  ?.  (~(has by collections.st) collection.key)  [%| 'Unknown collection.']
  ?.  (lth token.key (bex 256))  [%| 'Invalid token ID.']
  ?.  (fresh:policy st now collection.key)  [%| 'Ownership data is stale.']
  ?.  (eligible:policy st who key)  [%| 'This ship and NFT must have the same owner.']
  ?~  current=(~(get by claims.st) key)  [%| 'This NFT is unclaimed; use Claim membership.']
  ?:  =(who who.u.current)  [%| 'This NFT is already linked to this ship.']
  =/  cfg  (~(got by collections.st) collection.key)
  ?:  (~(has in suppressed.st) [group.cfg who])  [%| 'Membership is suppressed by the host.']
  =/  unix  (div (sub now ~1970.1.1) ~s1)
  ?.  &((gth expires unix) (lte expires (add unix 300)))  [%| 'Signature expired or expiry exceeds five minutes.']
  ?:  |(=(base-url.st '') (~(any in (silt (trip base-url.st))) |=(c=@t (lth c 32))))
    [%| 'The host must configure a valid public URL before wallet authorization.']
  =/  owner  (~(got by tokens.st) key)
  =/  generation  (~(gut by token-generations.st) key 0)
  [%& (crip "Gater association transfer v1\0aHost: {(trip (scot %p host))}\0aURL: {(trip base-url.st)}\0aChain ID: {(trip (decimal:j chain.cfg))}\0aContract: {(trip (addr:j contract.cfg))}\0aCollection: {(trip collection.key)}\0aToken: {(trip (decimal:j token.key))}\0aOwner: {(trip (addr:j owner))}\0aFrom ship: {(trip (scot %p who.u.current))}\0aTo ship: {(trip (scot %p who))}\0aRevision: {(trip (decimal:j expected))}\0aToken generation: {(trip (decimal:j generation))}\0aExpires at Unix seconds: {(trip (decimal:j expires))}\0aAuthorize only this association change. No NFT transfer or transaction.")]
++  personal-hash
  |=  msg=@t
  ^-  @
  =/  prefix  (cat 3 '\19Ethereum Signed Message:\0a' (decimal:j (met 3 msg)))
  =/  body  (cat 3 prefix msg)
  (keccak-256:keccak:crypto [(met 3 body) body])
++  recover
  |=  [msg=@t signature=@t]
  ^-  (unit @ux)
  ?.  =(132 (met 3 signature))  ~
  ?~  sig=(hex-number:j (crip (cass (trip signature))))  ~
  =/  v  (end 3 u.sig)
  =?  v  |(=(v 27) =(v 28))  (sub v 27)
  ?.  |(=(v 0) =(v 1))  ~
  =/  s  (cut 3 [1 32] u.sig)
  =/  r  (rsh [3 33] u.sig)
  =/  order  0xffff.ffff.ffff.ffff.ffff.ffff.ffff.fffe.baae.dce6.af48.a03b.bfd2.5e8c.d036.4141
  ?.  &((gth r 0) (lth r order) (gth s 0) (lte s (div order 2)))  ~
  =/  result
    %-  mule
    |.
    =/  pub
      %-  serialize-point:secp256k1:secp:crypto
      (ecdsa-raw-recover:secp256k1:secp:crypto (personal-hash msg) v r s)
    (end [3 20] (keccak-256:keccak:crypto [64 (rev 3 64 pub)]))
  ?-  -.result
    %|  ~
    %&  `p.result
  ==
++  claim
  |=  [st=state now=@da who=ship host=ship key=asset expected=@ud expires=@ud signature=@t]
  ^-  (each state @t)
  =/  msg  (message st now who host key expected expires)
  ?-  -.msg
    %|  [%| p.msg]
    %&  ?~  signer=(recover p.msg signature)  [%| 'Invalid wallet signature. Use a regular Ethereum key wallet.']
        ?.  =(`u.signer (~(get by tokens.st) key))  [%| 'The signature must be from the current NFT owner wallet.']
        (assign-token:policy st now who key expected)
  ==
++  challenge
  |=  [st=state now=@da who=ship host=ship jon=json]
  ^-  (each json @t)
  ?~  col=(slaw %tas (str:j jon 'collection'))  [%| 'Invalid collection.']
  ?~  token=(uint:j jon 'token')  [%| 'Invalid token ID.']
  ?~  expected=(uint:j jon 'revision')  [%| 'Missing state revision.']
  =/  expires  (add 300 (div (sub now ~1970.1.1) ~s1))
  =/  msg  (message st now who host [u.col u.token] u.expected expires)
  ?-  -.msg
    %|  [%| p.msg]
    %&  [%& (pairs:enjs:format ~[message+s+p.msg expires+s+(decimal:j expires) revision+s+(decimal:j u.expected) owner+s+(addr:j (~(got by tokens.st) [u.col u.token]))])]
  ==
--
