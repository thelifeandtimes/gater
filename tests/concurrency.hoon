=/  m  (strand ,vase)
=/  now  ~2026.10.29
=/  st  *state
=.  collections.st  (~(put by collections.st) %demo ['Demo' 1 0x1 %club %holder %invite '' &])
=.  owners.st  (~(put by owners.st) ~zod 0x1)
=.  tokens.st  (~(put by tokens.st) [%demo 1] 0x1)
=.  token-generations.st  (~(put by token-generations.st) [%demo 1] 100)
=.  azimuth-at.st  now
=.  nft-at.st  (~(put by nft-at.st) %demo now)
=/  revision  (claim-revision st ~zod [%demo 1])
~|  %unrelated-global-revision-does-not-conflict
=/  updated  st(revision 999)
?>  (expected-revision updated ~zod [%demo 1] revision)
=/  claimed  (claim-token updated now ~zod [%demo 1] revision)
?>  ?=(%& -.claimed)
~|  %transfer-generation-conflicts-even-when-owner-is-the-same
=/  moved  st(token-generations (~(put by token-generations.st) [%demo 1] 101))
?>  !(expected-revision moved ~zod [%demo 1] revision)
~|  %ship-ownership-conflicts
=/  moved  st(owners (~(put by owners.st) ~zod 0x2))
?>  !(expected-revision moved ~zod [%demo 1] revision)
~|  %another-claim-conflicts
=/  moved  st(claims (~(put by claims.st) [%demo 2] [~zod 0x1 2]))
?>  !(expected-revision moved ~zod [%demo 1] revision)
~|  %other-collection-does-not-conflict
=/  moved  st(claims (~(put by claims.st) [%elsewhere 2] [~zod 0x1 2]))
?>  (expected-revision moved ~zod [%demo 1] revision)
~|  %release-survives-unrelated-refresh
=/  owned  p.claimed
=/  release-rev  (claim-revision owned ~zod [%demo 1])
=/  released  (release owned(revision 2.000) ~zod [%demo 1] release-rev)
?>  ?=(%& -.released)
?>  =(~ claims.p.released)
~|  %release-kick-survives-role-removal-for-eligible-holder
=/  empty  p.released
=.  managed.empty  (silt ~[[%club ~zod]])
=.  applied.empty  (~(put by applied.empty) [%club ~zod] *(set @tas))
=/  reconciled  (reconcile empty now)
?>  (~(any by effects.reconciled) |=(ef=effect =(%kick kind.operation.ef)))
~|  %unclaimed-broad-invite-is-not-removed
=.  applied.empty  ~
=/  reconciled  (reconcile empty now)
?>  !(~(any by effects.reconciled) |=(ef=effect =(%kick kind.operation.ef)))
(pure:m !>([%gater-concurrency-tests 8 %passed]))
