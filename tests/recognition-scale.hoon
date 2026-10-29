::  Realistic source sizes without RPC, delivery, or saved fixture mutations.
=/  m  (strand ,vase)
=/  now  ~2026.10.28
=/  st  *state
=/  cfg=collection  ['Scale' 8.453 0xabc %club %holder %dm 'Claim:' &]
=.  collections.st  (~(put by collections.st) %scale cfg)
=.  azimuth-at.st  now
=.  nft-at.st  (~(put by nft-at.st) %scale now)
=.  owners.st
  %-  malt
  (turn (gulf 0 149.999) |=(who=@ud [`@p`who `@ux`(add 10.000 who)]))
=.  tokens.st
  %-  malt
  (turn (gulf 1 2.000) |=(token=@ud [[%scale token] `@ux`(add 500.000 token)]))
=.  tokens.st  (~(put by tokens.st) [%scale 1] 0x2710)
=.  owners.st  (~(put by owners.st) ~nec 0x2710)
~|  %large-source-none
=/  quiet  st(collections (~(put by collections.st) %scale cfg(recognition %none)))
?>  =(~ effects:(reconcile quiet now))
~|  %large-source-dm
=/  planned  (reconcile st now)
?>  =(2 ~(wyt by effects.planned))
?>  (~(all by effects.planned) |=(ef=effect &(!=(~bud who.seat.operation.ef) =(%dm kind.operation.ef))))
~|  %large-source-invite
=/  invited  st(collections (~(put by collections.st) %scale cfg(recognition %invite)))
?>  =(2 ~(wyt by effects:(reconcile invited now)))
~|  %same-address-other-collection-excluded
=.  tokens.st  (~(put by tokens.st) [%other 3] 0x2712)
?>  =(2 ~(wyt by effects:(reconcile st now)))
~|  %zero-and-comet-identities-excluded
=.  tokens.st  (~(put by tokens.st) [%scale 3] 0x0)
=.  owners.st  (~(put by owners.st) ~bud 0x0)
=.  owners.st  (~(put by owners.st) `@p`(bex 64) 0x2710)
?>  =(2 ~(wyt by effects:(reconcile st now)))
~|  %suppressed-and-recognized-excluded
=.  suppressed.st  (silt ~[[%club ~nec]])
=.  recognized.st  (silt ~[[%scale ~zod]])
?>  =(~ effects:(reconcile st now))
(pure:m !>([%gater-recognition-scale-tests 6 %passed]))
