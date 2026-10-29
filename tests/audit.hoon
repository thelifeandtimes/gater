::  Replay canonical L1 ownership events with Urbit's effective L2 rules.
=/  m  (strand ,vase)
=/  snap=snapshot  *snapshot
=/  event=event  *event
=.  address.event  0x223c.067f.8cf2.8ae1.73ee.5caf.ea60.ca44.c335.fecb
=.  data.event  '0x'
=.  topics.event  ~[0x16d0.f539.d49c.6cad.822b.767a.9445.bfb1.cf7e.a6f2.a6c2.b120.a7ea.4cc7.660d.8fda 0x0 0x123]
=.  mined.event  `[~ 0 0 0x1 1 0xabc |]
~|  %replay-populates-effective-owner
=/  result  (replay snap ~[event])
?>  =(`0x123 (~(get by owners.result) ~zod))
~|  %ownership-change-records-generation
?>  (~(has by generations.result) ~zod)
=/  changed  event(topics ~[i.topics.event 0x0 0x456], mined `[~ 0 0 0x2 2 0xdef |])
=/  result2  (replay snap ~[event changed])
?>  =(`0x456 (~(get by owners.result2) ~zod))
?>  !=(generations.result generations.result2)
~|  %l2-deposit-retains-effective-owner
=/  deposit  event(topics ~[i.topics.event 0x0 0x1111.1111.1111.1111.1111.1111.1111.1111.1111.1111], mined `[~ 0 0 0x3 3 0xfff |])
=/  result3  (replay snap ~[event deposit])
?>  =(owners.result owners.result3)
?>  =(generations.result generations.result3)
~|  %transfer-away-and-back-changes-generation
=/  back  event(mined `[~ 0 0 0x3 3 0xfff |])
=/  result4  (replay snap ~[event changed back])
?>  =(owners.result owners.result4)
?>  !=(generations.result generations.result4)
~|  %material-digest-binds-ordered-history
?>  !=((digest snap ~[event]) (digest snap ~[event changed]))
~|  %proof-expires-and-rejects-future-observations
=/  now  ~2026.10.29
=/  proof  *proof
?>  !enabled.proof
?>  !(fresh-proof proof now)
=.  proof  proof(enabled &, at now)
?>  (fresh-proof proof now)
?>  !(fresh-proof proof (add now ~m16))
?>  !(fresh-proof proof (sub now ~s1))
(pure:m !>([%gater-audit-tests 6 %passed]))
