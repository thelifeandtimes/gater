::  Acknowledgements, observed receipts and ownership accounting.
=/  m  (strand ,vase)
=/  now  ~2026.10.26
=/  st  *state
=/  log  *ledger
=/  op=operation  [%admit [%club ~zod] (silt ~[%holder]) '']
~|  %automatic-delivery-by-default
?>  enabled.log
?>  automatic:*controls
~|  %positive-ack-is-not-completion
=.  active.log  `[1 op op now %waiting ~ |]
=/  acked  (ack log 1 &)
?>  =(%acked phase:(need active.acked))
?>  =(~ history.acked)
?>  =(log (ack log 2 &))
~|  %negative-ack-is-retained
?>  =(%failed phase:(need active:(ack log 1 |)))
~|  %manual-role-is-satisfied-but-not-owned
=/  result=[st=state log=ledger]  (finish st log now *controls)
?>  (~(has in (~(got by applied.st.result) [%club ~zod])) %holder)
?>  =(~ (~(got by owned.log.result) [%club ~zod]))
?>  !(~(has in managed.st.result) [%club ~zod])
?>  ?=(~ active.log.result)
?>  ?=(^ history.log.result)
?>  =(%observed result.i.history.log.result)
~|  %new-seat-and-role-are-owned
=/  work  (need active.log)
=.  log  log(active `work(created &, added (silt ~[%holder])))
=/  result=[st=state log=ledger]  (finish st log now *controls)
?>  (~(has in managed.st.result) [%club ~zod])
?>  (~(has in (~(got by owned.log.result) [%club ~zod])) %holder)
~|  %preserved-manual-membership-relinquishes-management
=/  kick  op(kind %kick, roles ~)
=.  log.result  log.result(active `[2 kick kick(kind %revoke) now %waiting ~ |])
=/  result=[st=state log=ledger]  (finish st.result log.result now *controls)
?>  !(~(has in managed.st.result) [%club ~zod])
?>  !(~(has by owned.log.result) [%club ~zod])
?>  ?=(^ history.log.result)
?>  =(%preserved result.i.history.log.result)
~|  %production-requires-audit-and-respects-global-pause
=/  control=controls  *controls
=/  ready=ledger  log(enabled &, active ~, targets ~)
?>  (authorized st ready control | & op)
?>  !(authorized st ready control | | op)
?>  !(authorized st ready(enabled |) control | & op)
~|  %fake-ship-delivery-remains-explicitly-scoped
?>  !(authorized st ready control & | op)
?>  (authorized st ready(targets (silt ~[~zod])) control & | op)
~|  %manual-collection-requires-exact-approval
=/  cfg=collection  ['Club' 8.453 0xa %club %holder %none '' &]
=.  collections.st  (~(put by collections.st) %demo cfg)
=.  control  control(communities (~(put by communities.control) %demo [manual=& removal='A custom reason.']))
?>  !(authorized st ready control | & op)
=.  control  control(approvals (silt ~[op]))
?>  (authorized st ready control | & op)
?>  !(authorized st ready control | & op(roles (silt ~[%other])))
~|  %confirmed-kick-queues-one-custom-dm-with-rejoin-link
=.  base-url.st  'https://host.example'
=.  ready  ready(active `[2 kick kick now %acked ~ |])
=/  done=[st=state log=ledger]  (finish st ready now control)
?>  =(1 (lent ~(tap by notices.log.done)))
=/  notices  ~(tap by notices.log.done)
?>  ?=(^ notices)
=/  notice  q.i.notices
?>  =(%dm kind.notice)
?>  =('Club: A custom reason. https://host.example/gater/demo' text.notice)
?>  (~(any by effects.st.done) |=(ef=effect =(operation.ef notice)))
~|  %notice-survives-policy-reconciliation-and-reload
=/  restarted  !<(ledger !>(log.done))
=/  rebuilt=[st=state log=ledger]  (pending (reconcile:policy st.done now) restarted)
?>  =(notices.log.done notices.log.rebuilt)
?>  (~(any by effects.st.rebuilt) |=(ef=effect =(operation.ef notice)))
~|  %observed-dm-completes-once
=/  id  p.i.notices
=.  log.done  log.done(active `[id notice notice now %acked ~ |])
=/  delivered=[st=state log=ledger]  (finish st.done log.done now control)
?>  =(~ notices.log.delivered)
?>  ?=(^ history.log.delivered)
?>  =(%submitted result.i.history.log.delivered)
~|  %reclaimed-membership-cancels-unsent-removal-message
=.  claims.st.rebuilt  (~(put by claims.st.rebuilt) [%demo 1] [~zod 0x1 1])
=/  canceled=[st=state log=ledger]  (pending st.rebuilt log.rebuilt)
?>  =(~ notices.log.canceled)
?>  !(~(has by effects.st.canceled) id)
~|  %preserved-manual-membership-does-not-notify
=/  preserved=[st=state log=ledger]  (finish st ready(active `[2 kick kick(kind %revoke) now %acked ~ |]) now control)
?>  =(~ notices.log.preserved)
~|  %empty-removal-message-disables-notification
=.  control  control(communities (~(put by communities.control) %demo [| '']))
=/  silent=[st=state log=ledger]  (finish st ready now control)
?>  =(~ notices.log.silent)
~|  %migration-preserves-pause-and-does-not-notify-old-kicks
=/  old=ledger-6  [| ~ ~ ~ ~[[2 kick now %observed]]]
=/  migrated  (migrate old)
?>  !enabled.migrated
?>  =(history.old history.migrated)
?>  =(~ notices.migrated)
~|  %removal-barrier-is-scoped-to-the-group
=/  queued  st(effects (~(put by effects.st) 1 [kick %pending 0]))
?>  (removal-pending queued %club)
?>  !(removal-pending queued %unrelated)
(pure:m !>([%gater-delivery-tests 17 %passed]))
