::  Adapter safeguards and exact outgoing nouns, independent of live state.
=/  m  (strand ,vase)
=/  group  *group-view
=.  roles.group  (malt `(list [@tas *])`~[[%holder ~] [%manual ~] [%admin ~]])
=.  admins.group  (silt ~[%admin])
=/  ob  (observe group ~zod ~nec)
=/  op=operation  [%admit [%club ~zod] (silt ~[%holder]) '']
~|  %absent-member-can-be-invited-with-role
?>  (allowed op ob)
?>  !(observed op ob)
=+  [target=@tas cage]=(command op ob ~nec ~2026.10.26)
?>  =(%groups target)
?>  =(%group-action-5 p.cage)
?>  =(!<(* q.cage) [%group [~nec %club] %entry %pending (silt ~[~zod]) %add (silt ~[%holder])])
~|  %existing-member-gets-role-only
=.  seats.group  (~(put by seats.group) ~zod [(silt ~[%manual]) ~2026.10.26])
=/  ob  (observe group ~zod ~nec)
?>  member.ob
=+  [target=@tas cage]=(command op ob ~nec ~2026.10.26)
?>  =(!<(* q.cage) [%group [~nec %club] %seat (silt ~[~zod]) %add-roles (silt ~[%holder])])
~|  %role-observation-is-authoritative
?>  !(observed op ob)
?>  (observed op ob(roles (silt `(list @tas)`~[%holder %manual])))
~|  %revocation-preserves-other-roles
=/  revoke  op(kind %revoke)
=+  [target=@tas cage]=(command revoke ob ~nec ~2026.10.26)
?>  =(!<(* q.cage) [%group [~nec %club] %seat (silt ~[~zod]) %del-roles (silt ~[%holder])])
?>  (observed revoke ob)
~|  %pending-role-removal-preserves-manual-roles
=/  pending  ob(member |, pending &, roles (silt `(list @tas)`~[%holder %manual]))
=+  [target=@tas cage]=(command revoke pending ~nec ~2026.10.26)
?>  =(!<(* q.cage) [%group [~nec %club] %entry %pending (silt ~[~zod]) %edit (silt ~[%manual])])
~|  %host-admin-and-channel-host-protected
?>  !(allowed op (observe group ~nec ~nec))
?>  !(allowed op ob(protected &))
=/  admin  group(seats (~(put by seats.group) ~zod [(silt ~[%admin]) ~2026.10.26]))
?>  protected:(observe admin ~zod ~nec)
=/  channel  group(channels (~(put by channels.group) [%chat ~zod %example] ~))
?>  protected:(observe channel ~zod ~nec)
~|  %bans-block-grants-but-allow-removals
=.  ships.banned.admissions.group  (silt ~[~zod])
=/  banned  (observe group ~zod ~nec)
?>  !(allowed op banned)
?>  (allowed revoke banned)
=.  ships.banned.admissions.group  ~
=.  ranks.banned.admissions.group  (silt ~[%czar])
?>  banned:(observe group ~zod ~nec)
~|  %unknown-or-admin-roles-rejected
?>  !(allowed op(roles (silt ~[%missing])) ob)
?>  !(allowed op(roles (silt ~[%admin])) ob)
~|  %invite-and-kick-need-state-observation
?>  !(observed op(kind %invite) ob(member |, pending |, roles ~))
?>  (observed op(kind %invite) pending)
?>  !(observed op(kind %kick) pending)
?>  (observed op(kind %kick) ob(member |, pending |, roles ~))
~|  %dm-never-completes-from-group-state
?>  !(observed op(kind %dm) ob)
(pure:m !>([%gater-tlon-tests 10 %passed]))
